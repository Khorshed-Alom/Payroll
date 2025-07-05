//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Payroll {
    uint256 private s_empployeeId;
    uint256 private s_totalSalary;


    //address[] private s_employee;
    //address private s_Employees;
    address payable[] private s_payrollEmployee;

    struct EmployeeInfo {
        address employeeAddr;
        string name;
        uint256 birthYear;
        uint256 age;
        uint256 registrationTime;
        string positoin;
        uint256 id;
        uint256 monthlySalaryUsd;
        bool currentStatus;
    }
    EmployeeInfo employeeInfo;
    struct TerminationInfo {
        address employeeAddr;
        uint256 id;
        string position;
        uint256 workedDuration;
        uint256 terminationTime;
    }
    TerminationInfo terminationInfo;

    mapping (address => EmployeeInfo) public s_employeeLlist;
    mapping (uint256 => address) public s_employeeIdToAddr;
    mapping (address => TerminationInfo) public s_terminatedEmploye;

    function registerEmployee(
        address payable _employeeAddr,
        string memory _name,
        uint256 _birthYear,
        uint256 _age,
        string memory _positoin,
        uint256 _monthlySalaryUsd
        ) public {

        if (s_employeeLlist[_employeeAddr].employeeAddr == _employeeAddr) {
            revert;
        } else if (s_terminatedEmploye[_employeeAddr].employeeAddr == _employeeAddr) {
            revert;
        }
        EmployeeInfo memory info = EmployeeInfo ({
            employeeAddr: _employeeAddr, 
            name: _name,
            birthYear: _birthYear,
            age: _age, 
            registrationTime: block.timestamp, 
            positoin: _positoin, 
            id: s_empployeeId, 
            monthlySalaryUsd: _monthlySalaryUsd,
            currentStatus: true
        });
        s_employeeLlist[_employeeAddr] = info;

        s_employeeIdToAddr[s_empployeeId] = _employeeAddr;
        s_payrollEmployee.push(payable(_employeeAddr));
        s_empployeeId ++;
        s_totalSalary = _monthlySalaryUsd;
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
        terminationInfo = TerminationInfo({
            employeeAddr: _employeeAddr, 
            id: s_employeeLlist[_employeeAddr].id,
            position: s_employeeLlist[_employeeAddr].positoin,
            workedDuration: block.timestamp - s_employeeLlist[ _employeeAddr].registrationTime,
            terminationTime: block.timestamp
        });
        s_terminatedEmploye[_employeeAddr] = terminationInfo;

        delete s_employeeIdToAddr[s_employeeLlist[_employeeAddr].id];
        //delete s_payrollEmployee[s_employeeLlist[_employeeAddr].id];
        delete s_employeeLlist[_employeeAddr];
    }

    function payPayroll() public payable {
        if (!(msg.value > (s_totalSalary + 5 ether /** calculation needed */))) {}
    }

    function payRoll() public {
        s_payrollEmployee index = s_payrollEmployee.length;
        for (uint256 i = 0; i <= index; i++) {
            address payable payer = s_payrollEmployee[i];
            uint256 amount = s_employeeLlist[payer].monthlySalaryUsd;

            (bool sucsess, ) = payer.call{value:amount}("");
            if (!sucsess) {
                //try again later
            }
        }
    }

    function usdToEth() public {
        
    }
    //function checkUpkeep() public returns () {}

    function performUpkeep() public {}
    function claimSalary() public {}

    function registerDepartmentManager() public {}

    function registerTopLevelManager() public {}


    //fullfillRandomWords()
}