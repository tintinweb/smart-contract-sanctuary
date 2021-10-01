/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface BSCFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface BSCBnb {
    function balanceOf(address owner) external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
}

interface IBNB {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }
    function getOwner() external override view returns (address) {
        return owner();
    }
    function name() public override view returns (string memory) {
        return _name;
    }
    function symbol() public override view returns (string memory) {
        return _symbol;
    }
    function decimals() public override view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom (address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero'));
        return true;
    }
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }
    function _transfer (address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');
        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');
        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve (address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance'));
    }
}

contract TestToken is BEP20('TEST TOKEN', 'TEST111') {
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }
    mapping (address => address) internal _delegates;
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
    mapping (address => uint32) public numCheckpoints;
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
    mapping (address => uint) public nonces;
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "TOKEN::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "TOKEN::delegateBySig: invalid nonce");
        require(now <= expiry, "TOKEN::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "TOKEN::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }
        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2;
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }
    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;
        emit DelegateChanged(delegator, currentDelegate, delegatee);
        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }
    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }
            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }
    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "TOKEN::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }
    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}


contract InitialMOKOffering is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    TestToken public mock;
    uint256 private start;
    uint256 public mokPerBNB;

    bool isOver = false;
    bool isMaintained = false;
    bool isStarted = false;

    address private BNBAddr;
    address private BUSDAddr;
    address payable private factory;
    uint256 private bnbPrice;

    uint256 public bnbRaised;
    uint256 public busdRaised;

    int public totalInvestments = 0;
    uint256 public totalMOKDistributed = 0;

    uint256 public maxSupply = 2121232000000000000000000;

    BSCFactory public bscFactory;

    struct Investors{
        address _name;
        uint256 _mokStored;
        uint256 _bnbInvested;
        uint256 _busdInvested;
    }

    mapping (address => Investors) public investors;
    address[] public totalInvestors;
    uint256[] public salesData;

    uint256 public minInvestment = 10000000000000000;
    uint256 public maxInvestment = 10000000000000000000;
    
    
    uint256 dividend = 1000000000000000000;
    uint256 dividend1 = 1000000000000000000;

    event Returned(uint256 _invested, uint256 _mokDistributed);

    constructor (
        address _mock,
        uint256 _mokPerBNB,
        address _bscFactory,
        address _bnbAddress,
        address _busdAddress,
        address payable _factory
    ) public {
        mock = TestToken(_mock);
        mokPerBNB = _mokPerBNB;
        bscFactory = BSCFactory(_bscFactory);
        BNBAddr = _bnbAddress;
        BUSDAddr = _busdAddress;
        factory = _factory;
        getBNBinBUSD();
    }

    function getBNBinBUSD() private view returns (uint256, uint256){
        address pairAddress = bscFactory.getPair(BNBAddr, BUSDAddr);
        BSCBnb myBNB = BSCBnb(pairAddress);
        uint256 res1 = 0;
        uint256 res2 = 0;
        (res1, res2,) = myBNB.getReserves();
        return (res2, res1);
    }

    function mintMOK(address _to, uint256 _amount) internal {
        require(_to != address(0), 'Error: Cannot Transfer to address(0)');
        mock.transfer(_to, _amount);
    }

    function transOwner(address _newOwner) public onlyOwner {
        mock.transferOwnership(_newOwner); // TransferOwnership to _newOwner
    }


    function safeTransferMok(address _investor, uint256 _mocKAmount) internal {
        // require(mock.balanceOf(address(this)) <= _mocKAmount, 'Not Enough MOK to circulate');
        mintMOK(_investor, _mocKAmount); // SafeMinting to _investor address
    }

    function increaseSupply(uint256 increasedSupply) public onlyOwner {
        maxSupply += increasedSupply; // If in case of more demand on `MOK` supply
    }

    function priceMOK (uint256 _price) private onlyOwner {
        mokPerBNB = _price;
    }

    /*
    Investing BNB to the sale,
        - _investor, address of the Investor to mint `MOK` Tokens to

    Clarifies the investment process from this validations,
        - If IMO is over, no MOK to be minted after the IMO period ends
        - If IMO is not yet started, Minting to be done after the IMO has started
        - Validating from previous investments in the sales
        - Grouping investors with rewards from total investments
    */

    function investBNB(address _investor) public payable returns(bool status){
        require(!isOver, 'IMO has ended!');
        require(isStarted, 'IMO is not yet started!');

        require(_investor != address(0), 'Wut? A Zero Address Investor');
        require(msg.value >= minInvestment && msg.value <= maxInvestment, 'MOK Not Sold In This Amount! Please check minimum and maximum investment');
        require(totalMOKDistributed <= maxSupply, 'Out of MOK in Pre-Sale!');

        uint256 res1;
        uint256 res2;
        (res1, res2) = getBNBinBUSD();
        //uint256 _bnbPrice = res1.div(res2); // Init from reserves pair
        //uint256 busdPrice = (res2.mul(dividend)).div(res1); // Get BNB per BUSD

        

        (res2, res1) = getBNBinBUSD(); // Getting reserves from pool

        uint256 amountInvested = msg.value; // Total Invested Amount
        bool _status = false; // Initialize returning status
        bnbPrice = res2.div(res1); // Get BNB Price from Pool
        // bnbPrice = 342; // Get BNB Price from Pool

        if(isMaintained){
            factory.transfer(amountInvested.mul(10).div(100)); // SafeTransfer To Factory Address Fee Setter
        }
        
        uint256 mokDistributed1 = (amountInvested.mul(bnbPrice).mul(dividend).div(mokPerBNB));
        uint256 mokDistributed = (mokDistributed1.div(dividend));
        
        safeTransferMok(_investor, mokDistributed); // SafeTransfer MOK, Minting to _investor address
        // safeTransferMok(_investor,amountInvested);
        // safeTransferMok(_investor,bnbPrice);
        // safeTransferMok(_investor,mokPerBNB);
        
        assert(status = true); // No errors, status set to `True`
        emit Returned(amountInvested, mokDistributed);

        Investors memory invest = investors[_investor];
        if(invest._name == address(0)){ // Checking previous investments
            investors[_investor] = Investors(
                _investor,
                mokDistributed,
                msg.value,
                0
            );
            totalInvestors.push(_investor);
        }else{
            investors[_investor]._bnbInvested += amountInvested; // Adding BNB Investment
            investors[_investor]._mokStored += mokDistributed; // Adding distribution to previous stored data
        }
        bnbRaised += amountInvested; // BNB Raised
        totalMOKDistributed += mokDistributed; // Mok Distributed
        totalInvestments ++; // Total Investments increment
        salesData.push(mokDistributed); // Sales data for last mok sold
        return _status;
    }

    /*
        Get Minimum and Maximum BUSD to invest in the private sale.
        To distribute equally among the investors, we had set the total investments
        through a wallet to a limited quantity.
    */
    
    
    function setDividend(uint256 _dividend) public onlyOwner{
        dividend = _dividend;
    }

    function getMinBUSD() public view returns(uint256){
        uint256 res1;
        uint256 res2;
        (res1, res2) = getBNBinBUSD();
        uint256 _bnbPrice = res1.div(res2);
        return minInvestment.mul(_bnbPrice);
    }

    function getMaxBUSD() public view returns(uint256){
        uint256 res1;
        uint256 res2;
        (res1, res2) = getBNBinBUSD();
        uint256 _bnbPrice = res1.div(res2);
        return maxInvestment.mul(_bnbPrice);
    }
    function getMaxMOK() public view returns(uint256){
        uint256 _maxMOK = (maxInvestment.mul(mokPerBNB));
        return _maxMOK;
    }
    
    function getMOKinBUSD() public view returns (uint256){
        uint256 res1;
        uint256 res2;
        (res1, res2) = getBNBinBUSD();
        uint256 _busdPrice = (res2.mul(dividend)).div(res2);
        return _busdPrice.div(mokPerBNB);
    }

    /*
    Investing BUSD to the sale,
        - _investor, address of the Investor to mint `MOK` Tokens to
        - _amount, amount invested
    */

    function investBUSD(address _investor, uint256 _amount) public returns(bool status){
        require(!isOver, 'IMO has ended!');
        require(isStarted, 'IMO is not yet started!');

        require(_investor != address(0), 'Wtf? A Zero Address Investor');
        require(totalMOKDistributed <= maxSupply, 'Out of MOK in Pre-Sale!');

        /*
            Validating total investment from the _investor
        */
        uint256 res1;
        uint256 res2;
        (res1, res2) = getBNBinBUSD();
        uint256 _bnbPrice = res1.div(res2);
        uint256 busdPrice = 1;

        require(_bnbPrice != 0, 'Failed while fetching price!');
        require(busdPrice != 0, 'Failed while fetching price!');
        require(_amount > minInvestment.mul(_bnbPrice) && _amount < maxInvestment.mul(_bnbPrice), 'MOK Not Sold In This Amount! Please check minimum and maximum investment');

        if(investors[_investor]._name != address(0)){
            uint256 _totalMOKGiven = investors[_investor]._mokStored;
            uint256 _maxMOK = (maxInvestment.mul(mokPerBNB));
            require(_totalMOKGiven < _maxMOK, 'Whoa! Thats a lot of investment from you! :)');
        }

        /*
            SafeTransfer BUSD to the sale, in return `MOK` Tokens
        */

        IBEP20 busd = IBEP20(BUSDAddr);
        busd.safeTransferFrom(_investor, address(this), _amount);
        uint256 amountInvested = _amount;
        if(isMaintained){
            busd.safeTransfer(factory, _amount.mul(10).div(100)); // If is maintained, fee setter
        }
        bool _status = false;

        uint256 mokDistributed1 = (amountInvested.mul(dividend1).div(mokPerBNB)); // Calculating `MOK` Tokens minted per investment
        uint256 mokDistributed = (mokDistributed1.div(dividend1)); // Calculating `MOK` Tokens minted per investment
        safeTransferMok(_investor, mokDistributed1); // Transferring `MOK` to _investor
        assert(status = true); // No error, status set to `True`

        emit Returned(amountInvested, busdPrice);

        Investors memory invest = investors[_investor];
        if(invest._name == address(0)){ // New Investor data stored
            investors[_investor] = Investors(
                _investor,
                mokDistributed,
                0,
                amountInvested
            );
            totalInvestors.push(_investor);
        }else{
            investors[_investor]._busdInvested += amountInvested; // Adding BUSD investments
            investors[_investor]._mokStored += mokDistributed; // Adding `MOK` Distribution
        }
        totalMOKDistributed += mokDistributed; // Total `MOK` Minted
        busdRaised += amountInvested; // Total BUSD Raised
        totalInvestments ++; // Incrementing Total Investments

        salesData.push(mokDistributed); // Storing last `MOK` sold
        return _status;
    }

    function bnbLiquidity(address payable _reciever, uint256 _amount) public onlyOwner {
        _reciever.transfer(_amount); // Adding BNB Liquidity to MOK-BNB pool
    }

    function busdLiquidity(address _reciever) public onlyOwner {
        IBEP20 busd = IBEP20(BUSDAddr);
        busd.safeTransfer(_reciever, busd.balanceOf(address(this))); // Adding BUSD Liquidity to MOK-BUSD pool
    }

    function getInvestor(address _addr) public view returns (Investors memory invest) {
        return investors[_addr]; // Investor Details
    }

    function totalInvestor() public view returns (uint){
        return totalInvestors.length; // Total Investors / Token HOLDERS
    }

    function setMaxInvest(uint256 _invest) public onlyOwner {
        maxInvestment = _invest;
    }

    function setMinInvest(uint256 _invest) public onlyOwner {
        minInvestment = _invest;
    }

    function setperMOK(uint256 _amount) public onlyOwner {
        mokPerBNB = _amount;
    }

    function setStart(bool _start) public onlyOwner returns (uint){
        isStarted = _start;
    }

    function setOver(bool _start) public onlyOwner returns (uint){
        isOver = _start;
    }

    function setMaintained(bool _start) public onlyOwner returns (uint){
        isMaintained = _start;
    }
    function transferAnyERC20Token(address _investor,uint256 tokens)  public onlyOwner {
        safeTransferMok(_investor, tokens);
  }

}