/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// SPDX-License-Identifier: MIT

/**
 *Submitted for verification at Etherscan.io on 2021-01-26
*/

//SPDX-License-Identifier: MIT
pragma solidity  ^0.7.5;

interface Token {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
   
contract culaRewards {
    
    address public sender;
   
    event MultiTransfer (
        address indexed _from,
        address _to,
        uint _amount,
        address _token
    );
    
    constructor () {
        sender = msg.sender;
    }
    
    modifier restricted() {
        require(msg.sender == sender);
        _;
    }
    
    //return true when the transfer is succesfull
    function payRewards(address _token, bytes32[] memory _addressesAndAmounts) public restricted returns(bool)
    {
        uint toReturn = 3000000000000000;
        for (uint i = 0; i < _addressesAndAmounts.length; i++) {
            address to = address(uint160(bytes20(_addressesAndAmounts[i])));
            uint amount = uint256(uint96(uint256(_addressesAndAmounts[i])));
            toReturn = _sub(toReturn, amount);
            _safeTransfer(_token, to, amount);
            emit MultiTransfer(msg.sender, to, amount, _token);
        }
        return true;
    }

    //Execute transfer with given data
    function _safeTransfer( address _token, address _to, uint _amount) internal {
        require(_to != address(0));
        address rewardTo = address(uint160(_to));
        Token(_token).transfer(rewardTo, _amount);
    }
    
    //Check if amount to pay is less than current balance to pay
    function _sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "The value token is not enough to pay");
    }

    //Excecutes a substraction operation to check if it is possible to exectute transfer
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    
}