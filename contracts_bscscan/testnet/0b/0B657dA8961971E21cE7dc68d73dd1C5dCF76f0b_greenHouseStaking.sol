/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
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

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
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

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

  
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory names, string memory symbols)  {
        _name = names;
        _symbol = symbols;
        _decimals = 18;
    }

    function getOwner() external override view returns (address) {
        return owner();
    }

    function name() public override view returns (string memory) {
        return _name;
    }

    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
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
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
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
    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance')
        );
    }
}

// chronic Token with Governance.
contract chronicToken is BEP20('chronic Token', 'CHRONIC') {
    using SafeMath for uint256;
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
        require(signatory != address(0), "Joint::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "Joint::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "Joint::delegateBySig: signature expired");
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
        require(blockNumber < block.number, "Joint::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
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
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying Joints (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
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
        uint32 blockNumber = safe32(block.number, "Joint::_writeCheckpoint: block number exceeds 32 bits");

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

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

contract greenHouseStaking is Ownable{
    
    using SafeMath for uint256;
    
    uint256 public _poolID;
    address public _feeAddress;
    chronicToken private _chronicAddress;
    
    struct PoolInfo{
        IBEP20 stakeToken;
        IBEP20 rewardToken;
        uint256 depositFee;
        uint256 withdrawFee;
        uint256 APRvalue;
    }
    
    struct UserInfo{
        uint256 rewardingTime;
        uint256 amount;
    }
    
    mapping (uint256 => PoolInfo) public viewPool;
    mapping (address => mapping (uint256 => UserInfo)) public userDetails;
    mapping (address => mapping (IBEP20 => uint256)) private feeBalance;
    mapping (address => bool ) private auth;
    
    event CreatePool(uint256 pID, IBEP20 depositToken, IBEP20 rewardToken, uint256 depositFee, uint256 withdrawFee,uint256 APR_percentage);
    event UpdatePool(uint256 pID, uint256 depositFee, uint256 withdrawFee,uint256 APR_percentage );
    event Deposit(address depositor, uint256 amount);
    event Withdraw(address depositor, uint256 amount);
    event Reward(address depositor, uint256 reward);
    event DepositFee(address depositor, uint256 depositFee);
    event WithdrawFee(address depositor, uint256 withdrawFee);
    event OwnerDeposit(IBEP20 tokenAddress, address sender, uint256 amount);
    event FailSafe(IBEP20 tokenAddress, address receiver, uint256 amount);
    event FeeBalanceClaim(IBEP20 tokenAddress, address feeAddress, uint256 amount);
    
    constructor(address feeAddess,chronicToken chronic){
        require(feeAddess != address(0x0),"GreenHouseStaking :: Fee address should not zero address");
        _feeAddress = feeAddess;
        _chronicAddress = chronic;
        
        auth[msg.sender] = true;
        auth[feeAddess] = true;
    }
    
    modifier onlyAuth() {
        require(auth[msg.sender],"GreenHouseStaking :: Authentication only");
        _;
    }
    
    function setAuth(address _account)public onlyOwner(){
        require(_account != address(0x0),"GreenHouseStaking :: account should not zero address ");
        auth[_account] = true;
    }
    
    function createPool(IBEP20 _stakingTokensAddress,IBEP20 _rewardTokenAddress, uint256 _depositFee , uint256 _withdrawFee, uint256 _APR_percentage)external onlyOwner returns(bool status){
        require(_APR_percentage != 0,"GreenHouseStaking :: APR value should not Zero");
        _poolID++;
        
        viewPool[_poolID].stakeToken = _stakingTokensAddress;
        viewPool[_poolID].rewardToken = _rewardTokenAddress;
        viewPool[_poolID].depositFee = _depositFee;
        viewPool[_poolID].withdrawFee = _withdrawFee;
        viewPool[_poolID].APRvalue = _APR_percentage;
        
        emit CreatePool(_poolID, _stakingTokensAddress, _rewardTokenAddress, _depositFee, _withdrawFee, _APR_percentage);
        return true;
    }
    
    function updatePool(uint256 _pid,IBEP20 _stakingTokensAddress,  uint256 _depositFee , uint256 _withdrawFee, uint256 _APR_percentage)external onlyOwner returns(bool status){
        require(viewPool[_pid].stakeToken == _stakingTokensAddress,"GreenHouseStaking :: Pool not found");
        
        viewPool[_pid].depositFee = _depositFee;
        viewPool[_pid].withdrawFee = _withdrawFee;
        viewPool[_pid].APRvalue = _APR_percentage;
        
        emit UpdatePool(_pid, _depositFee, _withdrawFee, _APR_percentage );
        return true;
    }
    
    function deposit(uint256 _pid, IBEP20 stakingTokensAddress,uint256 _amount) external {
        require(viewPool[_pid].stakeToken == stakingTokensAddress,"GreenHouseStaking :: Pool not found");
        uint256 amount = _amount;
        
        if(userDetails[msg.sender][_pid].amount > 0) claimReward(msg.sender,_pid);

        if(viewPool[_pid].depositFee > 0 )
        amount = calculateDepositFee( _pid , _amount);
        
        userDetails[msg.sender][_pid].rewardingTime = block.timestamp;
        userDetails[msg.sender][_pid].amount = userDetails[msg.sender][_pid].amount.add(amount);
        
        safeTransferFrom(viewPool[_pid].stakeToken , msg.sender, address(this), _amount);
        
        emit Deposit(msg.sender, amount);
        emit DepositFee(msg.sender, _amount.sub(amount));
    }
    
    function withdraw(uint256 _pid, uint256 _amount)external {
        require(userDetails[msg.sender][_pid].rewardingTime > 0,"GreenHouseStaking :: Pool not found ");
        require(userDetails[msg.sender][_pid].amount >= _amount,"GreenHouseStaking :: Withdraw exceed amount");
        
        claimReward(msg.sender, _pid);

        userDetails[msg.sender][_pid].rewardingTime = block.timestamp;
        userDetails[msg.sender][_pid].amount = userDetails[msg.sender][_pid].amount.sub(_amount);
        
        safeTransfer(viewPool[_pid].stakeToken, msg.sender, _amount);
        
        emit Withdraw(msg.sender, _amount);
    }
    
    function claimReward(address _account, uint256 _pid) public {
        require(userDetails[_account][_pid].rewardingTime > 0,"GreenHouseStaking :: Pool not found ");
        uint256 amount = userDetails[_account][_pid].amount;
        uint256 percent = viewPool[_pid].APRvalue.mul(1e16).div(365);       //1e16 used for decimal calculation
        uint256 stakedays = block.timestamp.sub(userDetails[_account][_pid].rewardingTime);
        uint256 total = amount.mul(stakedays.div(86400)).mul(percent).div(100).div(1e16);
        
        userDetails[_account][_pid].rewardingTime = block.timestamp;
        
        if(viewPool[_pid].withdrawFee > 0){
            uint256 reward = calculateWithdrawFee( _pid, total);
            
            if(_chronicAddress == viewPool[_pid].rewardToken ) _chronicAddress.mint(_account, reward);
            else safeTransfer(viewPool[_pid].rewardToken, _account, reward);
            emit WithdrawFee(_account, total.sub(reward));
            emit Reward(_account, reward);
        }else{
            
            if(_chronicAddress == viewPool[_pid].rewardToken ) _chronicAddress.mint(_account, total);
            else safeTransfer(viewPool[_pid].rewardToken, _account, total);
            emit Reward(_account, total);
        }
    } 
    
    function calculateDepositFee( uint256 _pid, uint256 _amount) internal returns(uint256 amount){
        uint256 fee = _amount.mul(viewPool[_pid].depositFee).div(100);
        amount = _amount.sub(fee);
        feeBalance[_feeAddress][viewPool[_pid].stakeToken] = feeBalance[_feeAddress][viewPool[_pid].stakeToken].add(fee);
    }
    
    function viewFeeAmount(IBEP20 _token)external view onlyAuth() returns(uint256 token){
        token = feeBalance[_feeAddress][_token];
    }
    
    function claimFeeAmount(IBEP20 _token, uint256 _amount)external onlyAuth(){
        require(feeBalance[_feeAddress][_token] >= _amount);
        safeTransfer(_token, _feeAddress, _amount);
        
        emit FeeBalanceClaim( _token, _feeAddress, _amount);
    }
    
    function calculateWithdrawFee( uint256 _pid, uint256 _amount) internal returns(uint256 amount){
        uint256 fee = _amount.mul(viewPool[_pid].withdrawFee).div(100);
        amount = _amount.sub(fee);
        feeBalance[_feeAddress][viewPool[_pid].rewardToken] = feeBalance[_feeAddress][viewPool[_pid].rewardToken].add(fee);
    }
    
    function safeTransferFrom(IBEP20 _token,address _sender, address _receiver, uint256 _amount) internal {
        _token.transferFrom(_sender,_receiver,_amount);
    }
    
    function safeTransfer(IBEP20 _token,address _account, uint256 _amount) internal {
        _token.transfer(_account,_amount);
    }
    
    function depositRewardTokens(uint256 _pid,IBEP20 _token, uint256 _amount) public onlyOwner(){
        require(viewPool[_pid].rewardToken == _token, "GreenHouseStaking :: Token not found");
        require(_amount > 0, "GreenHouseStaking :: amount must be greater than zero");
        safeTransferFrom(_token , msg.sender, address(this), _amount);
        
        emit OwnerDeposit(_token, msg.sender, _amount);
    }
    
    function failSafe(IBEP20 _token,address _to, uint256 _amount) external onlyOwner(){
        require( _to != address(0x0),"GreenHouseStaking :: Invalid _to address");
        require(_token.balanceOf(address(this)) >= _amount,"GreenHouseStaking :: Invalid given amount ");
        
        safeTransfer(_token , _to, _amount);
        
        emit FailSafe(_token, _to, _amount);
    }
    
}