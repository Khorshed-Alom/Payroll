//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}


contract Payroll {
    //errors
    error Payroll__Unauthorized();
    error Payroll__AccessControlersCantBeMoreThanTen();
    error Payroll__ThisEmployeeIsAlreadyRgistered();

    IERC20 private token;

    uint256 private s_smartId;
    uint256 private s_totalSalary;

    address[] private s_accessControlers;
    address private s_chiefFinancialOfficer;
    address[] private s_hrManagers;
    address payable[] private s_payrollEmployee;

    // bool payrollAbilityToPay or uint256 private totalPayrollAbilityToPay

    struct EmployeeInfo {
        address employeeAddr;
        string name;
        uint256 registrationTime;
        string positoin;
        uint256 employeeId;
        uint256 smartId;
        uint256 monthlySalaryUsd;
        bool currentStatus;
    }
    struct TerminationInfo {
        address employeeAddr;
        uint256 employeeId;
        uint256 smartId;
        string position;
        uint256 terminationTime;
    }

    mapping(address => bool) public s_isControler;
    mapping(address => bool) s_isCFO;
    mapping(address => bool) public s_isHr;
    mapping(address => EmployeeInfo) public s_employeeLlist;
    mapping(uint256 => address) public s_employeeSmartIdToAddr;
    mapping(address => TerminationInfo) public s_terminatedEmploye;

    constructor(address accessControlerAddr, address _accessControlerAddr, address __accessControlerAddr, address usdtTokenAddr) {
        require(s_accessControlers.length < 10, Payroll__AccessControlersCantBeMoreThanTen());
        s_accessControlers.push(accessControlerAddr);
        s_accessControlers.push(_accessControlerAddr);
        s_accessControlers.push(__accessControlerAddr);
        token = IERC20(usdtTokenAddr);
        s_isControler[accessControlerAddr] = true;
        s_isControler[_accessControlerAddr] = true;
        s_isControler[__accessControlerAddr] = true;
    }

    modifier onlyAccessControlers() {
        require(s_isControler[msg.sender], Payroll__Unauthorized());
        _;
    }

    modifier onlyHrManagers() {
        require(s_isHr[msg.sender], Payroll__Unauthorized());
        _;
    }

    modifier onlyAccessControlersAndHrManagers() {
        require(s_isControler[msg.sender] || s_isHr[msg.sender], Payroll__Unauthorized());
        _;
    }

    modifier onlyAccessControlersAndChiefFinancialOfficer() {
        require(s_isControler[msg.sender] || s_isCFO[msg.sender], Payroll__Unauthorized());
        _;
    }

    function registerEmployee(
        address payable _employeeAddr,
        string memory _name,
        string memory _positoin,
        uint256 _employeeId,
        uint256 _monthlySalaryUsd
        ) public {

        require(s_employeeLlist[_employeeAddr].employeeAddr != _employeeAddr, Payroll__ThisEmployeeIsAlreadyRgistered());
        require(s_terminatedEmploye[_employeeAddr].employeeAddr != _employeeAddr, "");
        
        EmployeeInfo memory info = EmployeeInfo ({
            employeeAddr: _employeeAddr, 
            name: _name,
            registrationTime: block.timestamp,
            positoin: _positoin, 
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

    function changeEmployeeStatus(address _employeeAddr, bool status) public {
        if (s_terminatedEmploye[_employeeAddr].employeeAddr == _employeeAddr) {
            //revert AlreadyTerminated
        }
        if (!s_employeeLlist[_employeeAddr].currentStatus == status) {
            s_employeeLlist[_employeeAddr].currentStatus = status;
        } else {
            s_employeeLlist[_employeeAddr].currentStatus = status;
        }
    }
    
    // critical for payRoll. 
    function terminatEmployee(address _employeeAddr) internal {
        s_terminatedEmploye[_employeeAddr] = TerminationInfo({
            employeeAddr: _employeeAddr, 
            employeeId: s_employeeLlist[_employeeAddr].employeeId,
            smartId: s_employeeLlist[_employeeAddr].smartId,
            position: s_employeeLlist[_employeeAddr].positoin,
            terminationTime: block.timestamp
        });
        
        delete s_employeeSmartIdToAddr[s_employeeLlist[_employeeAddr].smartId];
        delete s_payrollEmployee[s_employeeLlist[_employeeAddr].smartId];
        delete s_employeeLlist[_employeeAddr];
    }

    function changeEmployeeSalary(address _employeeAddr, uint256 changedAmount) public {
        s_employeeLlist[_employeeAddr].monthlySalaryUsd = changedAmount;
    }

    function autoIncreaseSalaryAfter(uint256 month) public {
        
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

        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        payRoll();
    }

    function claimSalary() public {}

    function registerHrManager() public {}

    //function register() public {}

}