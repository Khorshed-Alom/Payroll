//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "src/IERC20.sol";
import {PayTime} from "src/PayTime.sol";

/** @title Payroll Contract
 *  @dev This contract manages employee payroll, including registration, salary payments, and access control.
 * 
 */
contract Payroll is PayTime {
    /** Errors */
    error Payroll__Unauthorized();
    error Payroll__AccessControlersCantBeMoreThanTen();
    error Payroll__AlreadyRgistered();
    error Payroll__AlreadyTerminated();
    error Payroll__Max90DaysAllowed();
    error Payroll__RestricTedTime();

    /** State Variables */
    IERC20 private immutable token;

    uint256 private s_smartId;
    uint256 private s_totalSalary;

    address[] private s_accessControlers;
    address private s_chiefFinancialOfficer;
    address[] private s_hrManagers;
    address payable[] private s_payrollEmployee;

    // bool payrollAbilityToPay or uint256 private totalPayrollAbilityToPay 

    struct EmployeeInfo {
        address employeeAddr;
        uint256 employeeId;
        uint256 smartId;
        uint256 monthlySalaryUsd;
        bool currentStatus;
    }
    struct TerminationInfo {
        address employeeAddr;
        uint256 employeeId;
        uint256 smartId;
    }

    mapping(address => bool) public s_isControler;
    mapping(address => bool) s_isCFO;
    mapping(address => bool) public s_isHr;
    mapping(address => EmployeeInfo) public s_employeeLlist;
    mapping(uint256 => address) public s_employeeSmartIdToAddr;
    mapping(address => TerminationInfo) public s_terminatedEmploye;

    constructor(
        address accessControlerAddr, 
        address _accessControlerAddr, 
        address __accessControlerAddr, 
        address daiTokenAddr,
        uint256 payMonthStartAfter_day,
        uint256 numberOfPayrollStartingMonth,
        uint256 currentYear) 
        PayTime(payMonthStartAfter_day, numberOfPayrollStartingMonth, currentYear) 
    {
        require(payMonthStartAfter_day <= 90, Payroll__Max90DaysAllowed());
        //require(s_accessControlers.length < 10, Payroll__AccessControlersCantBeMoreThanTen());

        s_accessControlers.push(accessControlerAddr);
        s_accessControlers.push(_accessControlerAddr);
        s_accessControlers.push(__accessControlerAddr);
        token = IERC20(daiTokenAddr);
        s_isControler[accessControlerAddr] = true;
        s_isControler[_accessControlerAddr] = true;
        s_isControler[__accessControlerAddr] = true;
    }

    modifier onlyAccessControlers() {
        require(s_isControler[msg.sender], Payroll__Unauthorized());
        require(restrictedTime(), Payroll__RestricTedTime());
        _;
    }

    modifier onlyHrManagers() {
        require(s_isHr[msg.sender], Payroll__Unauthorized());
        require(restrictedTime(), Payroll__RestricTedTime());
        _;
    }

    modifier onlyAccessControlersAndHrManagers() {
        require(s_isControler[msg.sender] || s_isHr[msg.sender], Payroll__Unauthorized());
        require(restrictedTime(), Payroll__RestricTedTime());
        _;
    }

    modifier onlyAccessControlersAndChiefFinancialOfficer() {
        require(s_isControler[msg.sender] || s_isCFO[msg.sender], Payroll__Unauthorized());
        require(restrictedTime(), Payroll__RestricTedTime());
        _;
    }

    function registerEmployee(
        address payable _employeeAddr,
        uint256 _employeeId,
        uint256 _monthlySalaryUsd)
        public 
        onlyHrManagers 
    {
        require(s_employeeLlist[_employeeAddr].employeeAddr != _employeeAddr, Payroll__AlreadyRgistered());
        require(s_terminatedEmploye[_employeeAddr].employeeAddr != _employeeAddr, "");
        
        EmployeeInfo memory info = EmployeeInfo ({
            employeeAddr: _employeeAddr, 
            employeeId: _employeeId,
            smartId: s_smartId, 
            monthlySalaryUsd: _monthlySalaryUsd,
            currentStatus: true
        });
        s_employeeLlist[_employeeAddr] = info;

        s_employeeSmartIdToAddr[s_smartId] = _employeeAddr;
        s_payrollEmployee.push(payable(_employeeAddr));
        s_smartId ++;
        s_totalSalary += _monthlySalaryUsd;
    }

    function changeEmployeeStatus(address _employeeAddr, bool status) public onlyAccessControlersAndHrManagers {
        require(s_terminatedEmploye[_employeeAddr].employeeAddr != _employeeAddr, Payroll__AlreadyTerminated());
        
        s_employeeLlist[_employeeAddr].currentStatus = status;
    }
    
    // critical for payRoll. 
    function terminatEmployee(address _employeeAddr) public onlyAccessControlersAndHrManagers {
        s_terminatedEmploye[_employeeAddr] = TerminationInfo({
            employeeAddr: _employeeAddr, 
            employeeId: s_employeeLlist[_employeeAddr].employeeId,
            smartId: s_employeeLlist[_employeeAddr].smartId
        });
        
        delete s_employeeSmartIdToAddr[s_employeeLlist[_employeeAddr].smartId];
        delete s_payrollEmployee[s_employeeLlist[_employeeAddr].smartId];
        delete s_employeeLlist[_employeeAddr];
    }

    function changeEmployeeSalary(address _employeeAddr, uint256 changedAmount) public onlyAccessControlersAndChiefFinancialOfficer {
        s_employeeLlist[_employeeAddr].monthlySalaryUsd = changedAmount;
    }

    function payPayroll() public payable {
        token.transferFrom(msg.sender, address(this), s_totalSalary);
    }

    function payRoll() public {
        uint256 index = s_payrollEmployee.length + 1;
        for (uint256 i = 0; i <= index; i++) {
            address payable payer = s_payrollEmployee[i];
            uint256 amount = s_employeeLlist[payer].monthlySalaryUsd;

            bool sucsess = token.transfer(payer, amount);

        }
    }

    function checkUpkeep(bytes calldata /* checkData */) external view returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = true;
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        payrollStarter();
        nextMonthStarter();
    }


    function registerHrManager(address hrManager) public {

    }

    function claimSalary() public {
        //require();
        // address payable payer = s_payrollEmployee[i];
        // uint256 amount = s_employeeLlist[payer].monthlySalaryUsd;

        // bool sucsess = token.transfer(payer, amount);
    }

}