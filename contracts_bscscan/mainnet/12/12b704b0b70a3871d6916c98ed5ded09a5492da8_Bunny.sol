/**
 *Submitted for verification at BscScan.com on 2022-01-09
*/

// SPDX-License-Identifier: Unlicensed

/*
 * Copyright © 2022 onebunny.org - all rights reserved.
 */

pragma solidity ^0.8.11;

interface IBunny {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function ReadAllowance(address spender, address allowance_provider) external returns (uint);

    function RBFReset(uint newRBF) external returns (bool);

    function currentRBF() external returns (uint);

    function LockProvidedLiquidityForever() external returns (bool);

    function RebaseRevocation() external returns (bool);

    function newVoting(uint Options) external returns (bool);

    function vote(uint Option) external returns (bool);

    function readVotingResults() external returns (uint[] memory);
    
    function ResetVoting() external returns (bool);

    function SetInheritance(address recipient, uint tagen) external returns (bool);

    function CancelInheritance(address recipient) external returns (bool);

    function ClaimInheritance(address AccountToInheritValueFrom) external returns (bool);

    function TimeperiodOfInheritance(address AccountToInheritValueFrom) external returns (uint);

    function WhichAccountWillReceiveInheritance(address Grantor) external returns (address);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    event Vote(address indexed owner, uint Option, uint AccountPower);
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return (a & b) + (a ^ b) / 2;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return a / b + (a % b == 0 ? 0 : 1);
    }

    function abs(int256 n) internal pure returns (uint256)
    {
        unchecked
        {
            return uint256(n >= 0 ? n : -n);
        }
    }
}

library Arrays {
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256)
    {
        if (array.length == 0)
        {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high)
        {
            uint256 mid = Math.average(low, high);
            if (array[mid] > element)
            {
                high = mid;
            }
            else
            {
                low = mid + 1;
            }
        }

        if (low > 0 && array[low - 1] == element)
        {
            return low - 1;
        }
        else
        {
            return low;
        }
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256)
    {
        unchecked
        {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256)
    {
        unchecked
        {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256)
    {
        unchecked
        {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256)
    {
        unchecked
        {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256)
    {
        unchecked
        {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
    {
        unchecked
        {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
    {
        unchecked
        {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
    {
        unchecked
        {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Address {
    function isContract(address account) internal view returns (bool)
    {
        uint256 size;
        assembly
        {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal
    {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory)
    {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory)
    {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory)
    {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory)
    {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory)
    {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory)
    {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory)
    {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory)
    {
        if (success) {return returndata;}
        else
        {
            if (returndata.length > 0)
            {
                assembly
                {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            }
            else
            {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Start {
    function _msgSender() internal view virtual returns (address)
    {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata)
    {
        return msg.data;
    }
}

contract Bunny is Start, IBunny {
    using Address for address;
    using SafeMath for uint;

    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowance;
    mapping(address => mapping(address => uint)) private WPFI; // waiting period for inheritance
    mapping(address => mapping(address => bool)) private IC; // inheritance claim
    mapping(address => address) private IR; // Inheritance Recipient
    mapping(address => uint) private MyPotNow;
    mapping(address => uint) private Staked;

    bool public VotingOpen;
    uint[] private VoteArray;
    address[] private Voters;

    uint private INITS = 100000000 * 10 ** 14;
    uint private RBF = 100000;
    uint private TotalSupply = INITS;
    uint public decimals = 14;
    uint private lastRBFReset;
    uint private Pot;

    bool LPProvided = false;
    bool RebaseRevocated = false;

    string public name = "KBunny";
    string public symbol = "1KBUNNY";
    
    address public OneBunny = 0xad028683316106E02Be47fCe3982a059517d2A57; // CHANGE;
    address public BunnyMarket = 0x65b3b947b4FBaf9037769b4AdDF662d97dbD0873; // 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address public BunnyDevDep = 0x9fD5656BF76F9019047ad3aa292ed4c9bA6A006e; // 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address public BunnyBurner = 0x43c9f90A5F42464Eb46D280779F9Ac070dB7d799; // 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
    address public StakedBunny = 0x5b0737B86be3F02aFBcf596743a501F508DCd68d; // 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;

    constructor() {
        balances[msg.sender] = TotalSupply.mul(RBF);
    }

    function totalSupply() public view returns (uint)
    {
        return TotalSupply.mul(RBF);
    }

    function balanceOf(address owner) public view returns(uint)
    {
        return balances[owner]*RBF;
    }

    function allowanceOf(address spender) public view returns(uint)
    {
        return allowance[msg.sender][spender]*RBF;
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(msg.sender != StakedBunny, "Absolutely not, this is the reward pot of holders!");
        require(msg.sender != address(0), "The zero address can not send bunnies away, it holds them all tightly! <3");
        require(balanceOf(msg.sender) >= value, "Damn, your balance is too low :( buy more bunnies!");
        //require(balances[to]+value < totalSupply.mul(4).div(1000), "Anti-Whale Protection activated, you may not perform this transaction.");
        if((msg.sender == OneBunny) && (LPProvided == false))
        {
            balances[to] += value;
        }
        else
        {
            //require(value < totalSupply.mul(5).div(100000), "Anti-Rug Protection activated, you may not tranfer more than 0,05% of the total supply in one go.");
            balances[to] += value.mul(978).div(RBF).div(1000);
            balances[OneBunny] += value.mul(3).div(RBF).div(1000);
            balances[BunnyMarket] += value.mul(3).div(RBF).div(1000);
            balances[BunnyDevDep] += value.mul(3).div(RBF).div(1000);
            balances[BunnyBurner] += value.mul(3).div(RBF).div(1000);
            balances[StakedBunny] += value.div(RBF).div(100);
            Pot += value.div(RBF).div(100);
            balances[msg.sender] -= value.div(RBF);
        }
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(address(from) != StakedBunny, "Absolutely not, this is the reward pot of holders!");
        require(address(from) != address(0), "The zero address can not send bunnies away, it holds them all tightly! <3");
        require(balanceOf(from) >= value, "Damn, your balance is too low :( buy more bunnies!");
        require(allowance[from][msg.sender] >= value.mul(RBF), "Your allowance is too low.");
        //require(balances[to]+value < totalSupply.mul(4).div(1000), "Anti-Whale Protection activated, you may not execute this transaction.");
        if((from == OneBunny) && (LPProvided == false))
        {
            balances[to] += value;
        }
        else
        {
            //require(value < totalSupply.mul(5).div(100000), "Anti-Rug Protection activated, you may not tranfer more than 0,05% of the total supply in one go.");
            balances[to] += value.mul(978).div(RBF).div(1000);
            balances[OneBunny] += value.mul(3).div(RBF).div(1000);
            balances[BunnyMarket] += value.mul(3).div(RBF).div(1000);
            balances[BunnyDevDep] += value.mul(3).div(RBF).div(1000);
            balances[BunnyBurner] += value.mul(3).div(RBF).div(1000);
            balances[StakedBunny] += value.div(RBF).div(100);
            Pot += value.div(RBF).div(100);
            balances[from] -= value.div(RBF);
        }
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }

    function ReadAllowance(address spender, address allowance_provider) public view returns (uint) {
        return allowance[allowance_provider][spender];
    }

    function RBFReset(uint newRBF) public returns (bool)
    {
        require(RebaseRevocated == false, "Rebase has been revocated forever.");
        require(msg.sender == OneBunny, "Only the SnowBunny can alter the RBF ^-^");
        require(((newRBF >= 1) && (newRBF <= 100000)), "Value not in acceptabled range, retry.");
        require((block.timestamp - lastRBFReset) >= 43200, "You may reset the RBF only twice per day.");
        lastRBFReset = block.timestamp;
        RBF = newRBF;
        return true;
    }

    function currentRBF() public view returns (uint)
    {
        return RBF;
    }

    function LockProvidedLiquidityForever() public returns (bool)
    {
        require(LPProvided == false, "Liquidity has been provided and securely locked forever. The Bunny has to pay taxes now.");
        require(msg.sender == OneBunny, "Only the Bunny can call this function, once.");
        LPProvided = true;
        return true;
    }

    function RebaseRevocation() public returns (bool)
    {
        require(RebaseRevocated == false, "The Rebase functionality has already been revocated forever.");
        require(msg.sender == OneBunny, "Only the Bunny can revocate the Rebase functionality.");
        RebaseRevocated = true;
        return true;
    }

    function newVoting(uint Options) public returns (bool)
    {
        require(msg.sender == OneBunny, "Only the Bunny can call this function.");
        VoteArray = new uint[](Options) ;
        VotingOpen = true;
        return true;
    }

    function vote(uint Option) public returns (bool)
    {
        if(Voters.length > 0)
        {
            for(uint i = 0; i < Voters.length; i++)
            {
                require(Voters[i] != msg.sender, "You already voted in this round.");
            }
        }
        require(VotingOpen == true, "Currently there is no voting taking place.");
        require(balances[msg.sender] >= 1, "You must own at least one Bunny to vote.");
        require((Option >= 1) && (Option <= VoteArray.length), "You didn't enter a valid vote.");
        VoteArray[Option-1] += 1;
        Voters.push(msg.sender);
        emit Vote(msg.sender, Option, balances[msg.sender]);
        return true;
    }

    function readVotingResults() public view returns (uint[] memory)
    {
        return VoteArray;
    }
    
    function ResetVoting() public returns (bool)
    {
        require(VotingOpen == true, "What's the point in reseting a non-existing voting? :0");
        require(msg.sender == OneBunny, "Only the Bunny can reset the voting.");
        delete VoteArray;
        delete Voters;
        VotingOpen = false;
        return true;
    }

    function SetInheritance(address recipient, uint tagen) public returns (bool)
    {
        require(recipient != msg.sender, "This is futile.");
        require(tagen >= 500, "A waiting period of at least 500 days must be set to avoid dishonest use of this function.");
        WPFI[msg.sender][recipient] = block.timestamp.add(tagen.mul(24).mul(60).mul(60));
        IC[msg.sender][recipient] = true;
        IR[msg.sender] = recipient;
        return true;
    }

    function CancelInheritance(address recipient) public returns (bool)
    {
        require(IC[msg.sender][recipient] == true, "There is no inheritance to be cancelled.");
        WPFI[msg.sender][recipient] = 0;
        IC[msg.sender][recipient] = false;
        IR[msg.sender] = msg.sender;
        return true;
    }

    function ClaimInheritance(address AccountToInheritValueFrom) public returns (bool)
    {
        require(IC[AccountToInheritValueFrom][msg.sender] == true, "There is no inheritance to be claimed.");
        require(block.timestamp >= WPFI[AccountToInheritValueFrom][msg.sender], "You still need to wait before inheriting bunnies :3");
        balances[msg.sender] += balances[AccountToInheritValueFrom];
        balances[AccountToInheritValueFrom] = 0;
        return true;
    }

    function TimeperiodOfInheritance(address AccountToInheritValueFrom) public view returns (uint)
    {
        require(IC[AccountToInheritValueFrom][msg.sender] == true, "You currently have no active inheritance from this address.");
        require(WPFI[msg.sender][AccountToInheritValueFrom].div(86400).add(1) > 0, "You may claim your inheritance now. Take care <3");
        return WPFI[msg.sender][AccountToInheritValueFrom].div(86400).add(1);
    }

    function WhichAccountWillReceiveInheritance(address Grantor) public view returns (address)
    {
        if(IR[Grantor] == address(0))
        {
            return msg.sender;
        }
        else
        {
            return IR[msg.sender];
        }
    }

    function BunnyHub(uint amount) public returns (bool)
    {
        require(amount <= balances[msg.sender], "You don't own that many bunnies!");
        balances[msg.sender] += (Pot.sub(MyPotNow[msg.sender])).mul(Staked[msg.sender].div(totalSupply().mul(100)))+Staked[msg.sender];
        balances[StakedBunny] -= (Pot.sub(MyPotNow[msg.sender])).mul(Staked[msg.sender].div(totalSupply().mul(100)));
        balances[msg.sender] -= amount;
        Staked[msg.sender] = amount;
        MyPotNow[msg.sender] = Pot;
        return true;
    }

    function BunnyRewardNow() public view returns (uint)
    {
        require(Staked[msg.sender] != 0, "You haven't staked any bunnies - this is futile.");
        return (Pot.sub(MyPotNow[msg.sender])).mul(Staked[msg.sender].mul(10000000000000000).div(totalSupply().div(100000000000000)));
    }

    function StakedBunnies() public view returns (uint)
    {
        return Staked[msg.sender];
    }

    function UnstakeAll() public returns (bool)
    {
        require(Staked[msg.sender] != 0, "You haven't staked any bunnies - this is futile.");
        balances[msg.sender] += (Pot.sub(MyPotNow[msg.sender])).mul(Staked[msg.sender].div(totalSupply().mul(100)))+Staked[msg.sender];
        balances[StakedBunny] -= (Pot.sub(MyPotNow[msg.sender])).mul(Staked[msg.sender].div(totalSupply().mul(100)));
        Staked[msg.sender] = 0;
        return true;        
    }
}