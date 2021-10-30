// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface ISharesTimeLock {
    function depositByMonths(uint256 amount, uint256 months, address receiver) external;
}

contract Incetivizer {
    
    uint256 constant MONTHS = 36;
    address public constant multisig = address(0x6458A23B020f489651f2777Bd849ddEd34DfCcd2);
    address public constant DOUGH = address(0xad32A8e6220741182940c5aBF610bDE99E737b2D);
    address public constant veDOUGH = address(0xE6136F2e90EeEA7280AE5a0a8e6F48Fb222AF945);
    address public constant sharesTimelock = address(0x6Bd0D8c8aD8D3F1f97810d5Cc57E9296db73DC45);

    modifier onlyMultisig() {
        require(msg.sender == multisig, "Not multisig");
        _;
    }
    
    function approve(uint256 amount) external onlyMultisig {
        IERC20(DOUGH).approve(sharesTimelock, amount);
    }
    
    function incetivizeHARD(address[] calldata recipients, uint256[] calldata values) external onlyMultisig {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
            
        require(IERC20(DOUGH).transferFrom(multisig, address(this), total));
        
        for (uint256 i = 0; i < recipients.length; i++)
            ISharesTimeLock(sharesTimelock).depositByMonths(values[i], MONTHS, recipients[i]);
    }
    
    function withdrawStuckFunds(address _token, address _receiver, uint256 _amount) public onlyMultisig {
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(_receiver).transfer(_amount);
        } else {
            IERC20(_token).transfer(multisig, _amount);
        }
    }
}