//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract PayTime {
    uint256 internal s_payMonth;
    uint256 private immutable i_payMonthStarter;
    uint256 internal s_numberOfMonth;
    uint256 private s_years;
    uint256 internal s_safeTime;
    
    bool private s_stoper;

    constructor(uint256 payMonthStartAfter_day, uint256 numberOfPayrollStartingMonth, uint256 currentYear) {
        i_payMonthStarter = block.timestamp +  (payMonthStartAfter_day * 1 days);
        s_numberOfMonth = numberOfPayrollStartingMonth;
        s_years = currentYear;
    }

    function payrollStarter() internal {

        if (block.timestamp >= i_payMonthStarter && (!s_stoper)) {
            s_payMonth = block.timestamp + daysOfMonth(s_numberOfMonth);
            s_safeTime = block.timestamp + 10 days;
            s_stoper = true;
        }
    }

    function nextMonthStarter() internal {
        if (s_payMonth <= block.timestamp) {
            s_payMonth = block.timestamp + daysOfMonth(s_numberOfMonth);
            s_safeTime = block.timestamp + 10 days;
        }
    }
 
    function restrictedTime() internal returns(bool status){
        if (s_safeTime >= block.timestamp) {
            return status = true;
        } else {
            return status = false;
        }
    }
    
    function daysOfMonth(uint256 numberOfMonth) internal view returns(uint24) {
        if (numberOfMonth == 2 && leapyear(s_years) == 0) {
            uint24 daysOfFebruary = 29 days;
            return daysOfFebruary;
        
        } else {
            uint24[12] memory daysOf = [
                31 days, // January
                28 days, // February
                31 days, // March
                30 days, 
                31 days, 
                30 days,
                31 days, 
                31 days, 
                30 days, 
                31 days, 
                30 days, 
                31 days // December
            ];
            return daysOf[numberOfMonth -1];
        }
    }

    function leapyear(uint256 _years) internal pure returns(uint256 yearsLeft) {
      return yearsLeft = _years % 4;
    }

    function increasePayMonthLength() public {

    } 
    function decreasePayMonthLength() public {
        
    }
}