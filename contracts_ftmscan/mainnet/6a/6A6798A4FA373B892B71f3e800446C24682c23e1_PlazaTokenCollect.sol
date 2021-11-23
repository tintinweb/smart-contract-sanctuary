/**
 *Submitted for verification at FtmScan.com on 2021-11-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IToken {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract PlazaTokenCollect {
    using SafeMath for uint256;
    
    address public tokenAddr = 0xC1e9D0d0A5353DEe8b0fb23f1e03b21fc91566EF; // Plaza Token
    address public sendAddr = 0xD7a52A194733adb733Dad8032025a16d791cEFE5;
    address public newTokenAddr = 0x3C146ff186e438f60EF63E3Da101984a72DB9f1C; // New Plaza Token
    address public newTokenOwner = 0x67537A7786Be4FfbDf48a8BA2fD906cfF9Cb697D;
    address owner; // Owner of contract
    uint8 _decimals = 9;
    
    // Stores info on individual swaps
    struct swapInstance {
        address userAddrs;
        uint256 amount;
    }
    
    // Init array of swaps
    swapInstance[] swaps; 

    modifier owneronly() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _owner) public owneronly {
        owner = _owner;
    }

    function setSendAddress(address _sendAddr) external owneronly {
        sendAddr = _sendAddr;
    }

    function setTokenAddress(address _tokenAddr) external owneronly {
        tokenAddr = _tokenAddr;
    }

    function setNewTokenOwner(address _ownerAddr) external owneronly {
        newTokenOwner = _ownerAddr;
    }
    
    function setNewTokenAddress(address _tokenAddr) external owneronly {
        newTokenAddr = _tokenAddr;
    }

    function getBalanceOfToken(address userAddress)
        external
        view
        returns (uint256)
    {
        return IToken(tokenAddr).balanceOf(userAddress);
    }
       

    constructor() {
        owner = msg.sender;
    }
    
    function getSwaps() public owneronly view returns(swapInstance[] memory) {
        return swaps;
    }
    
    function getUserDeposits(address userAddress) external view returns (uint256) {
        uint256 totalDeposit = 0;
        for (uint i=0; i < swaps.length; i++)
            if (swaps[i].userAddrs == userAddress) {
                totalDeposit += swaps[i].amount;
            }
        return totalDeposit;
    }
    
    function transfer(uint256 amount) public {
        require(amount > 0, "You need to send at least some tokens");
        
        IToken token = IToken(tokenAddr);
        uint256 oldTokenBalance = token.balanceOf(msg.sender);

        // Limit token amount
        require(amount <= oldTokenBalance, "The amount is greater than your Plaza balance");
        
        // Create a new swapInstance struct to store swap details
        swapInstance memory swapThis = swapInstance(msg.sender, amount.div(10**_decimals));
        
        // Push swap details struct into array
        swaps.push(swapThis);

        // Transfer Old Plaza tokens to withdraw address
        token.transferFrom(msg.sender, sendAddr, amount);

        IToken newToken = IToken(newTokenAddr);
        // Transfer New Plaza tokens to the holder
        newToken.transferFrom(newTokenOwner, msg.sender, amount);
    }
}