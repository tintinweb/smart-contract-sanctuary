//SourceUnit: BaseTRC20.sol

pragma solidity ^0.5.8;

import "./ITRC20.sol";
import "./Context.sol";
import "./SafeMath.sol";

contract BaseTRC20 is Context, ITRC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "TRC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "TRC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "TRC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint amount) internal {
        require(account != address(0), "TRC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint amount) internal {
        require(account != address(0), "TRC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "TRC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract TRC20Detailed is BaseTRC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;


    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}



//SourceUnit: Context.sol

pragma solidity ^0.5.8;

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

//SourceUnit: ITRC20.sol

pragma solidity ^0.5.8;

contract TRC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract ITRC20 is TRC20Events {
    function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(
        address src, address dst, uint wad
    ) public returns (bool);
}




//SourceUnit: LOLToken.sol

pragma solidity ^0.5.8;

import "./Context.sol";
import "./ITRC20.sol";
import "./BaseTRC20.sol";

contract LOLToken is ITRC20, TRC20Detailed {

    mapping(address => bool) freezeAccount;
    mapping(address => bool) public signers;
    mapping(address => bool) private vote;
    uint private totalTrueVotes = 0;
    bool public result = false;
    uint pendingTransactionID = 1;
    
    uint[] public pendingTransactionList;
    
    uint public currentTotalSupply;
    uint public deployDate;
    uint public launchDate;
    
    uint public unlockDate2months;
    uint public unlockDate4months;
    uint public unlockDate8months;
    uint public unlockDate12months;
    uint public unlockDate35days;
    uint public unlockDate56days;
    
    uint public firstType;
    uint public secondType;
    uint public thirdType;
    
    address public owner;
    
    address[] buyerCount;
    mapping(address => Buyer) public buyers;
    struct Buyer 
    {
        address buyerAddress;
        uint amount1;
        uint amount2;
        uint amount3;
        uint amount4;
    
        uint totalAmount;
        uint totalAmount1;
    }
    
    mapping(uint => OwnerTransaction) public ownerTransactions;
    struct OwnerTransaction 
    {
        address to;
        uint amount;
        string status;
        uint allowedTime;
    }
    
    event TransferedFromCurrentSupply(uint from, address indexed to, uint256 value);
    
    event BoughtTokenDuringLaunch(address from, address to, uint256 amount);
    event BoughtToken(address from, address to, uint256 amount);
    event SoldToken(address from, address to, uint256 amount);
    
    
    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner of this smart contract. Contact info@futiracoin.com for help.");
        _;
    }
    
    modifier onlySigner {
        require(signers[msg.sender] == true, "You are not the signer of this smart contract. Contact info@futiracoin.com for help.");
        _;
    }


    constructor( address _signer1, address _signer2) public TRC20Detailed("LOLTOKEN", "LOL", 6){
        _mint(msg.sender, 6000000000 * 10 ** 6);
        currentTotalSupply += 1000 * (10 ** 6);
        
        deployDate = block.timestamp;
    	launchDate = deployDate + 900;
        unlockDate35days = deployDate + 1000;
        unlockDate56days = deployDate + 1100;
        unlockDate2months = launchDate + 900;
        unlockDate4months = launchDate + 1000;
        unlockDate8months = launchDate + 1200;
        unlockDate12months = launchDate + 1400;
    
        firstType = deployDate + 300; 
        secondType = deployDate + 500;
        thirdType = deployDate + 800; 
    
        pendingTransactionList.push(0);
    
        owner = msg.sender;
    
        // the signer will forever be the same
        // change this into the signer address
        signers[_signer1] = true;
        signers[_signer2] = true;
    }

    // For signers to cast their vote
    function signersApproval(bool _signersVote) onlySigner public{
    
        if (_signersVote == true)
        {
             if(totalTrueVotes < 2)
            {
                totalTrueVotes += 1;
            }
        }
        else {
            if(totalTrueVotes > 0)
            {
                totalTrueVotes -= 1;
            }
        }
    
        if (totalTrueVotes >= 1){
            result = true;
        }
        else if (totalTrueVotes == 0) {
            result = false;
        }
    }
    
    // To get a detail about a pending transaction
    function getPendingTransaction(uint _id) public view returns(address, uint, string memory, uint) 
    {
        if(msg.sender != owner && signers[msg.sender] != true)
        {
            revert("You are not the owner or signer of this smart contract. Contact info@futiracoin.com for help.");
        }
        return (ownerTransactions[_id].to, ownerTransactions[_id].amount, ownerTransactions[_id].status, ownerTransactions[_id].allowedTime);
    }
    
     // To get number of last pending transaction and count of not signed
     function getcurrentPendingTransactions() public view returns( uint, uint) 
    {
        if(msg.sender != owner && signers[msg.sender] != true)
        {
            revert("You are not the owner or signer of this smart contract. Contact info@futiracoin.com for help.");
        }
        uint count = 0;
        for(uint i = 0; i<pendingTransactionList.length; i++){
        if(pendingTransactionList[i] != 0){   
        count++;
        }    
        }
        return (pendingTransactionList.length - 1, count);
    }

    // To get a list of pending transaction 
    function getAllPendingTransaction() public view returns(uint[] memory) 
    {
        if(msg.sender != owner && signers[msg.sender] != true)
        {
            revert("You are not the owner or signer of this smart contract. Contact info@futiracoin.com for help.");
        }

        return pendingTransactionList;
    }
    
    // For admin to freeze any account
    function freezeAnAccount(address _address) onlyOwner public
    {
        freezeAccount[_address] = true;
    }
    
    // For admin to unfreeze any account
    function unfreezeAnAccount(address _address) onlyOwner public
    {
        freezeAccount[_address] = false;
    }
    
    function setTotalSupply(string memory operation, uint _amount) onlyOwner public returns(uint) 
    {
        if(keccak256(abi.encodePacked((operation))) == keccak256(abi.encodePacked(("add"))))
        {
            _mint(msg.sender, _amount);
            currentTotalSupply += _amount;
        }
        else if(keccak256(abi.encodePacked((operation))) == keccak256(abi.encodePacked(("delete"))))
        {
            require(currentTotalSupply >= _amount, "The amount is greater than the total supply. Contact info@futiracoin.com for help.");
            _burn(msg.sender, _amount);
            currentTotalSupply -= _amount;
        }
        else
        {
            revert("This operation is not acceptable. Contact info@futiracoin.com for help.");
        }
    
        return totalSupply();
    }
    
    // To transfer the token from the owner to the _to address
    function _transferFromContract(address _to, uint256 _value) internal {
        require(_to != address(0), "Error with the buyer address. Contact info@futiracoin.com for help.");
    
        _transfer(owner, _to, _value);
        currentTotalSupply -= _value;
    
        emit TransferedFromCurrentSupply(balanceOf(owner), _to, _value);
    }
    
    // To get the buyer details on token they have on each type
    function getBuyer(address _address) public view returns(address, uint, uint, uint, uint, uint, uint)
    {
        if(buyers[_address].buyerAddress == _address)
        {
            return (buyers[_address].buyerAddress, buyers[_address].amount1, buyers[_address].amount2, buyers[_address].amount3, buyers[_address].amount4, buyers[_address].totalAmount, buyers[_address].totalAmount1);
        }
        else
        {
            revert("Cannot find this address. Contact info@futiracoin.com for help.");
        }
    }
    
    function transfer(address _to, uint256 _amount) public returns(bool)
    {
        require(!freezeAccount[msg.sender], "Your address has been hold from transfering the token. Contact info@futiracoin.com for help.");
    
        if(msg.sender == owner)
        {
           deleteExceededTimePendingTransaction();
           createPendingTransaction(_to, _amount);
        }
        else
        {
    
            if(block.timestamp > unlockDate12months)
            {
                uint permissableAmount = buyers[msg.sender].amount1 + buyers[msg.sender].amount2 + buyers[msg.sender].amount3 + buyers[msg.sender].amount4 ;
                if(_amount > permissableAmount)
                {
                    revert("The amount you want to transfer is higher than you're allowed. Contact info@futiracoin.com for help.");
                }
    
                uint totalAmount = buyers[_to].amount4 + _amount;
                uint totalAmount2 = buyers[_to].totalAmount + _amount;
                buyers[msg.sender].totalAmount -= _amount;              
                buyers[_to].buyerAddress = _to;
                buyers[_to].amount4 = totalAmount;
                buyers[_to].totalAmount = totalAmount2;
                uint balance;
                balance = updateAmount(msg.sender, _amount,100);
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 2);}
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 3);}
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 4);}
                _transfer(msg.sender, _to, _amount);             
    
            }
            else if (block.timestamp > unlockDate8months)
            {
    
                uint soldOutPercent = ((buyers[msg.sender].totalAmount1 - buyers[msg.sender].amount1) / 100) * buyers[msg.sender].totalAmount1;
                uint percentFinal = 55 - soldOutPercent;
                uint permissableAmount = (buyers[msg.sender].amount1 * percentFinal / 100) + buyers[msg.sender].amount2 + buyers[msg.sender].amount3 + buyers[msg.sender].amount4 ;
                if(_amount > permissableAmount)
                {
                    revert("The amount you want to sell is higher than you're allowed. Contact info@futiracoin.com for help.");
                }
    
                buyers[msg.sender].totalAmount -= _amount;
                buyers[_to].buyerAddress = _to;
                buyers[_to].amount4 = buyers[_to].amount4 + _amount;
                buyers[_to].totalAmount += _amount;
    
                uint balance;
                balance = updateAmount(msg.sender, _amount, 55);
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 2);}
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 3);}
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 4);}
                 _transfer(msg.sender, _to, _amount);             
            }
            else if (block.timestamp > unlockDate4months)
            {
                uint permissableAmount = buyers[msg.sender].totalAmount1 * 10/100 + buyers[msg.sender].amount2 + buyers[msg.sender].amount3 + buyers[msg.sender].amount4 ;
                if(_amount > permissableAmount)
                {
                    revert("The amount you want to sell is higher than you're allowed. Contact info@futiracoin.com for help.");
                }
    
                buyers[msg.sender].totalAmount -= _amount;
                buyers[_to].buyerAddress = _to;
                buyers[_to].amount4 = buyers[_to].amount4 + _amount;
                buyers[_to].totalAmount += _amount;
    
                uint balance;
                balance = updateAmount(msg.sender, _amount, 10);
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 2);}
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 3);}
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 4);}
                 _transfer(msg.sender, _to, _amount);          
            }
            else if (block.timestamp > unlockDate2months)
            {
                uint permissableAmount = buyers[msg.sender].amount2 + buyers[msg.sender].amount3 + buyers[msg.sender].amount4 ;
                if(_amount > permissableAmount)
                {
                    revert("The amount you want to sell is higher than you're allowed. Contact info@futiracoin.com for help.");
                }
    
                buyers[msg.sender].totalAmount -= _amount;
                buyers[_to].buyerAddress = _to;
                buyers[_to].amount4 = buyers[_to].amount4 + _amount;
                buyers[_to].totalAmount += _amount;            
                uint balance;
                balance = updateAmount(msg.sender, _amount, 2);
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 3);}
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 4);}
                 _transfer(msg.sender, _to, _amount);           
            }              
            else
            {
                revert("You can't transfer these tokens. Contact info@futiracoin.com for help.");
            }
    
            if (_to == owner )
            {
                buyers[_to].totalAmount =balanceOf(_to) ;    
            }
        }
        return true;
    }
    
    // to transfer from an address to another address and store in amount4
    function transferFrom(address sender, address _to, uint256 _amount) onlyOwner public returns(bool)
    {
        if(_to == owner)
        {
            _transfer(sender, _to, _amount);
            currentTotalSupply += _amount;
    
            buyers[sender].totalAmount -= _amount;
    
            uint balance;
            balance = updateAmount(sender, _amount, 100);
            if(balance != 0) {balance = updateAmount(sender, balance, 2);}
            if(balance != 0) {balance = updateAmount(sender, balance, 3);}
            if(balance != 0) {balance = updateAmount(sender, balance, 4);}
    
        }
        else if (sender == owner)
        {
            deleteExceededTimePendingTransaction();
            createPendingTransaction(_to, _amount);
        }
        else
        {
            _transfer(sender, _to, _amount);
            buyers[sender].totalAmount -= _amount;
    
            buyers[_to].buyerAddress = _to;
            buyers[_to].amount4 = buyers[_to].amount4 + _amount;
            buyers[_to].totalAmount += _amount;
    
            uint balance;
            balance = updateAmount(sender, _amount, 100);
            if(balance != 0) {balance = updateAmount(sender, balance, 2);}
            if(balance != 0) {balance = updateAmount(sender, balance, 3);}
            if(balance != 0) {balance = updateAmount(sender, balance, 4);}
        }
    
        return true;
    }
    
    // To update the buyer amount of token in their respective type
    function updateAmount(address _buyer, uint256 _amount, uint buyerType) internal returns(uint)
    {
        if(buyerType == 100)
        {
            if(buyers[_buyer].amount1 >= _amount)
            {
                buyers[_buyer].amount1 = buyers[_buyer].amount1 - _amount;
                return 0;
            }
            else
            {
                buyers[_buyer].amount1 = 0 ;
                return _amount - buyers[_buyer].amount1;
            }
        }
        else if(buyerType == 55)
        {
            uint soldOutPercent = ((buyers[msg.sender].totalAmount1 - buyers[msg.sender].amount1) / 100) * buyers[msg.sender].totalAmount1;
            uint percentFinal = 55 - soldOutPercent;
    
            if(buyers[_buyer].amount1 * percentFinal / 100 >= _amount)
            {
                buyers[_buyer].amount1 = buyers[_buyer].amount1 - _amount;
                return 0;
            }
            else
            {
                uint balance = _amount - buyers[_buyer].amount1 * percentFinal / 100;
                buyers[_buyer].amount1 = buyers[_buyer].amount1 -  buyers[_buyer].totalAmount1 * percentFinal / 100;
                return balance;
            }
        }
        else if(buyerType == 10)
        {
            if(buyers[_buyer].totalAmount1 * 10/100 >= _amount)
            {
                buyers[_buyer].amount1 = buyers[_buyer].amount1 - _amount;
                return 0;
            }
            else
            {
                uint balance = _amount - buyers[_buyer].totalAmount1 * 10/100;
                buyers[_buyer].amount1 = buyers[_buyer].amount1 -  buyers[_buyer].totalAmount1 * 10/100;
                return balance;
            }
        }
        else if(buyerType == 2)
        {
            if(buyers[_buyer].amount2 >= _amount)
            {
                buyers[_buyer].amount2 = buyers[_buyer].amount2 - _amount;
                return 0;
            }
            else
            {
                uint balance = _amount - buyers[_buyer].amount2;
                buyers[_buyer].amount2 = 0 ;
                return balance;
            }
        }
        else if(buyerType == 3)
        {
            if(buyers[_buyer].amount3 >= _amount)
            {
                buyers[_buyer].amount3 = buyers[_buyer].amount3 - _amount;
                return 0;
            }
            else
            {
                uint balance = _amount - buyers[_buyer].amount3;
                buyers[_buyer].amount3 = 0 ;
                return balance;
            }
        }
        else if(buyerType == 4)
        {
            if(buyers[_buyer].amount4 >= _amount)
            {
                buyers[_buyer].amount4 = buyers[_buyer].amount4 - _amount;
                return 0;
            }
            else
            {
                uint balance = _amount - buyers[_buyer].amount4;
                buyers[_buyer].amount4 = 0 ;
                return balance;
            }
        }
    
        return 0;
    }
    
    // To check whether an ID is in the pendingTransactionList
    function checkPendingTransactionList(uint _id) internal view returns(bool)
    {
        for(uint i = 0; i < pendingTransactionList.length; i++)
        {
            if(pendingTransactionList[i] == _id)
            {
                return true;
            }
        }
    
        return false;
    }
    
    // To change the status into failed and delete all the pending transaction that has exceed the time allowed
    function deleteExceededTimePendingTransaction() internal
    {
        for(uint i = 0; i < pendingTransactionList.length; i++)
        {
            bool check = checkPendingTransactionList(i);
            if(check && block.timestamp > ownerTransactions[i].allowedTime)
            {
                ownerTransactions[i].status = "failed";
                delete pendingTransactionList[i];
            }
        }
    }
    
    // This function will create a pending transaction for signer to sign
    function createPendingTransaction(address _to, uint _amount) internal returns(uint)
    {
        uint id =  pendingTransactionID;
        ownerTransactions[id] = OwnerTransaction(_to, _amount, "pending", block.timestamp + 300);
        pendingTransactionList.push(id);
    
        pendingTransactionID = pendingTransactionID + 1;
    
        return id;
    }
    
    // for signer to approve all the transaction in the pendingTransactionList
    function approveAllPendingTransaction() onlySigner public
    {
        for(uint i = 0; i < pendingTransactionList.length; i++)
        {
            uint id =  pendingTransactionList[i];
            bool check = checkPendingTransactionList(id);
            if(check)
            {
                if(ownerTransactions[id].allowedTime > block.timestamp && keccak256(abi.encodePacked((ownerTransactions[id].status))) == keccak256(abi.encodePacked(("pending"))))
                {
                    approvePendingTransaction(id);
                }
            }
        }
    }
    
    // for signer to approve a transaction in the pendingTransactionList
    function approvePendingTransaction(uint _id) onlySigner public
    {
        uint id = _id;
        bool check = checkPendingTransactionList(id);
        require(check, "This ID is not in the transaction pending list. Contact info@futiracoin.com for help.");
        require(result, "Did not have permission from signer. Contact info@futiracoin.com for help.");
    
        if(ownerTransactions[id].allowedTime > block.timestamp && keccak256(abi.encodePacked((ownerTransactions[id].status))) == keccak256(abi.encodePacked(("pending"))))
        {
            address _to = ownerTransactions[id].to;
            uint _amount = ownerTransactions[id].amount;
    
            if(block.timestamp <= firstType)
            {
                uint totalAmount = buyers[_to].amount1 + _amount;
                uint totalAmount2 = buyers[_to].totalAmount + _amount;
                buyers[_to].buyerAddress = _to;
                buyers[_to].amount1 = totalAmount;
                buyers[_to].totalAmount1 = totalAmount;
                buyers[_to].totalAmount = totalAmount2;
                _transferFromContract(_to, _amount);
            }
            else if(block.timestamp < secondType && block.timestamp > firstType)
            {
                uint totalAmount = buyers[_to].amount2 + _amount;
                uint totalAmount2 = buyers[_to].totalAmount + _amount;
                buyers[_to].buyerAddress = _to;
                buyers[_to].amount2 = totalAmount;
                buyers[_to].totalAmount = totalAmount2;
                _transferFromContract(_to, _amount);
            }
            else if(block.timestamp < thirdType && block.timestamp > secondType)
            {
                uint totalAmount = buyers[_to].amount3 + _amount;
                uint totalAmount2 = buyers[_to].totalAmount + _amount;
                buyers[_to].buyerAddress = _to;
                buyers[_to].amount3 = totalAmount;
                buyers[_to].totalAmount = totalAmount2;
                _transferFromContract(_to, _amount);
            }
            else
            {
                uint totalAmount = buyers[_to].amount4 + _amount;
                uint totalAmount2 = buyers[_to].totalAmount + _amount;
                buyers[_to].buyerAddress = _to;
                buyers[_to].amount4 = totalAmount;
                buyers[_to].totalAmount = totalAmount2;
                _transferFromContract(_to, _amount);
            }
    
            ownerTransactions[id].status = "successful";
            delete pendingTransactionList[id];
            emit SoldToken(msg.sender, ownerTransactions[id].to, ownerTransactions[id].amount);
        }
        else if(block.timestamp > ownerTransactions[id].allowedTime)
        {
            ownerTransactions[id].status = "failed";
            delete pendingTransactionList[id];
        }
        else if(keccak256(abi.encodePacked((ownerTransactions[id].status))) == keccak256(abi.encodePacked(("successful"))))
        {
            revert("This transaction is already already successful . Contact info@futiracoin.com for help.");
        }
        else
        {
            revert("This transaction failed. Contact info@futiracoin.com for help.");
        }
    
    }
}


//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}