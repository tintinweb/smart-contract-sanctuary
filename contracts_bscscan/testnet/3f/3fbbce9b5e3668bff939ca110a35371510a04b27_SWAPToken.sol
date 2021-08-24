/**
 *Submitted for verification at BscScan.com on 2021-08-23
*/

pragma solidity ^0.6.0;

// ----------------------------------------------------------------------------
// Symbol      : SWAP
// Name        : CAO DINH SWAP TOKEN
// Total supply: 1997,000,000.000000
// Decimals    : 6
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function addSafe(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");
    }

    function subSafe(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, "SafeMath: subtraction overflow");
        c = a - b;
    }

    function mulSafe(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "SafeMath: multiplication overflow");
    }

    function divSafe(uint a, uint b) internal pure returns (uint c) {
        require(b > 0, "SafeMath: division by zero");
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
interface IBSC {
    /**
    * Returns the amount of tokens in existence.
    */
    function totalSupply() external view returns (uint);
    /**
    * Returns the amount of tokens owned by `account`.
    */
    function balanceOf(address account) external view returns (uint balance);
    /**
    * Returns the remaining number of tokens that `spender` will be
    * allowed to spend on behalf of `tokenOwner` through {transferFrom}. This is
    * zero by default.
    *
    * This value changes when {approve} or {transferFrom} are called.
    */
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    /**
	* Moves `amount` tokens from the caller's account to `recipient`.
	* Returns a boolean value indicating whether the operation succeeded.
	* Emits a {Transfer} event.
	*/
    function transfer(address recipient, uint amount) external returns (bool success);
    /**
    * Sets `amount` as the allowance of `spender` over the caller's tokens.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * IMPORTANT: Beware that changing an allowance with this method brings the risk
    * that someone may use both the old and the new allowance by unfortunate
    * transaction ordering. One possible solution to mitigate this race
    * condition is to first reduce the spender's allowance to 0 and set the
    * desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    *
    * Emits an {Approval} event.
    */
    function approve(address spender, uint amount) external returns (bool success);
    /**
	* Moves `amount` tokens from `sender` to `recipient` using the
	* allowance mechanism. `amount` is then deducted from the caller's
	* allowance.
	*
	* Returns a boolean value indicating whether the operation succeeded.
	*
	* Emits a {Transfer} event.
	*/
    function transferFrom(address sender, address recipient, uint amount) external returns (bool success);
    /**
	* Emitted when `value` tokens are moved from one account (`from`) to
	* another (`to`).
	*
	* Note that `value` may be zero.
	*/
    event Transfer(address indexed from, address indexed to, uint tokens);
    /**
	* Emitted when the allowance of a `spender` for an `tokenOwner` is set by
	* a call to {approve}. `value` is the new allowance.
	*/
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
interface ApproveAndCallFallBack {
    function receiveApproval(address tokenOwner, uint256 amount, address tokenContract, bytes calldata data) external;
}


// Migrate to new Service Contract
interface Migrate_SWAPTokenService {
    function migrate(uint _BXTBAmount, uint VICC) external;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// BEP20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract SWAPToken is ApproveAndCallFallBack, IBSC, Owned {
    using SafeMath for uint;

    address public constant BXTB = 0xF896fe97511EAf6af3Eb33EBFae4079811d0C387;      // BXTB contract address
    address public constant VICC = 0x055B51471102a4EdC1544F1Ce102C1e74B6C12CA;      // VICC contract address

    bool public deprecate = false;

    uint public totalSupplyVICC;
    uint public totalSupplyBXTB;

    address public migrateNewAddress;


    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    uint _totalOutstanding;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        symbol = "SWAP";
        name = "Cao Dinh SWAP Token";
        decimals = 6;
        _totalSupply = 1997000000 * 10 ** uint(decimals);
        // 1997000000 * 10^6
        balances[address(this)] = _totalSupply;
    }

    // When new coins are distributed after contract creation
    event Mint(uint _amount);
    event Exchange(address indexed from, address indexed to, uint amount);
    event ReceiveApprovalData(address _tokenOwner, uint256 _amount, address _tokenContract);
    event TotalSupplyVICCChanged(uint _amount);

    // ----------------------------------------------------------------------------
    // Standard BEP20 implementations
    // ----------------------------------------------------------------------------
    function totalSupply() public view override returns (uint) {
        return _totalSupply.subSafe(balances[address(0)]);
        // Less burned tokens
    }

    function balanceOf(address account) public view override returns (uint balance) {
        return balances[account];
    }

    function transfer(address recipient, uint amount) public override returns (bool success) {
        balances[msg.sender] = balances[msg.sender].subSafe(amount);
        balances[recipient] = balances[recipient].addSafe(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) public override returns (bool success) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public override returns (bool success) {
        balances[sender] = balances[sender].subSafe(amount);
        allowed[sender][msg.sender] = allowed[sender][msg.sender].subSafe(amount);
        balances[recipient] = balances[recipient].addSafe(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ----------------------------------------------------------------------------
    // Other common and courtesy functions
    // ----------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    function transferAnyBEP20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return IBSC(tokenAddress).transfer(owner, tokens);
    }
    // Tokens outstanding
    function totalOutstanding() public view returns (uint) {
        return _totalOutstanding.subSafe(balances[address(0)]);
        // Less burned tokens
    }
    // Let contract owner mint tokens
    function mint(uint _amount) public onlyOwner {
        balances[address(this)] = balances[address(this)].subSafe(_amount);
        balances[owner] = balances[owner].addSafe(_amount);
        emit Transfer(address(this), owner, _amount);
        _totalOutstanding = _totalOutstanding.addSafe(_amount);
        emit Mint(_amount);
    }


    function receiveApproval(address _tokenOwner, uint256 _amount, address _tokenContract, bytes memory) public override {
        emit ReceiveApprovalData(_tokenOwner, _amount, _tokenContract);
        if (!deprecate) {
            if (msg.sender == VICC) {
                // Update
                totalSupplyVICC = totalSupplyVICC.addSafe(_amount);

                uint allowanceSwapExpected = _amount.mulSafe(3).divSafe(2);

                IBSC(VICC).transferFrom(_tokenOwner, address(this), _amount);
                IBSC(address(this)).transfer(_tokenOwner, allowanceSwapExpected);

                emit TotalSupplyVICCChanged(totalSupplyVICC);
            } else if (msg.sender == BXTB) {
                uint allowanceVICCExpected = _amount.mulSafe(5).divSafe(2);

                // Update
                totalSupplyBXTB = totalSupplyBXTB.addSafe(_amount);
                totalSupplyVICC = totalSupplyVICC.subSafe(allowanceVICCExpected);


                IBSC(BXTB).transferFrom(_tokenOwner, address(this), _amount);
                IBSC(VICC).transfer(address(this), allowanceVICCExpected);

                emit TotalSupplyVICCChanged(totalSupplyVICC);
            }
        }
    }

    function deprecateReceiveApproval(bool _deprecate) external onlyOwner {
        deprecate = _deprecate;
    }

    function startMigrate(address _newContract) external onlyOwner {
        // Transfer all BXTB
        uint transferAmount = IBSC(BXTB).balanceOf(address(this));
        // Take all coins, including accidental ones
        IBSC(BXTB).transfer(_newContract, transferAmount);

        // Transfer all VICC
        transferAmount = IBSC(VICC).balanceOf(address(this));
        // Take all coins, including accidental ones
        IBSC(VICC).transfer(_newContract, transferAmount);

        Migrate_SWAPTokenService(_newContract).migrate(totalSupplyVICC, totalSupplyBXTB);
        migrateNewAddress = _newContract;

        // Reset local counters
        totalSupplyBXTB = 0;
        totalSupplyVICC = 0;
    }

}