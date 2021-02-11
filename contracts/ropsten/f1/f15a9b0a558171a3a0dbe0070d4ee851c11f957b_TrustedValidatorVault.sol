/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-27
*/

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    constructor () internal {}
    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    mapping(address => uint256) public lockValueData;

    function getLockData(address who) public view returns (uint256){
        return lockValueData[who];
    }
    // lock amount in account
    function _lock_erc(address account, uint256 amount) internal {
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        lockValueData[account] = lockValueData[account].add(amount);
        emit Transfer(account, address(0), amount);

    }
    // unlock amount in account
    function _unlock_erc(address account) internal {
        _balances[account] = _balances[account].add(lockValueData[account]);
        emit Transfer(address(0), account, lockValueData[account]);
        lockValueData[account] = 0;
    }
}

contract ERC20Detailed is IERC20 {
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        // solhint-disable-next-line avoid-call-value
        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract TrustedValidatorVault is ERC20, ERC20Detailed {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    struct Detail {
        uint8 commission;
        string name;
        string website;
        string description;
    }

    IERC20 public token;

    // candidate detail
    mapping(address => Detail) holderDetail;

    address public governance;

    // list candidate
    address[] private candidates;

    uint256 public minDeposit = 750 * 10 ** 18;
    uint256 public minDelegate = 500 * 10 ** 18;
    /**
    *  phase 0: set list candidate, only candidate deposit, withdraw (set by governance)
    *  phase 1: allow delegate deposit, delegate withdraw (set by governance)
    *  phase 2: was set in lockRanking() function, lock voting result
    **/
    uint8 public phase;

    mapping(address => address) public  ResultVotePhase0;
    /**
    * voter address->candidate address -> value
    * value = delegateVote + selfVote
    **/
    mapping(address => mapping(address => uint256)) private voteResult;

    /**
    * candidate address ->voter address[]
    * This variable to get list address delegate candidate to lock asset
    **/
    mapping(address => address[]) private candidateVoter;

    /**
    *  In phase 2, result voting will be record in this
    **/
    mapping(address => uint256) private ranking;

    // timestamp to unlock asset
    uint256 public timeRelease;

    // duration to lock asset
    uint256 public lockDuration;

    constructor (address _token) public ERC20Detailed(
        string(abi.encodePacked("oraiCommunityStake")),
        string(abi.encodePacked("oraiCommunityStake")),
        ERC20Detailed(_token).decimals()
    ) {
        token = IERC20(_token);
        governance = msg.sender;
        phase = 0;
        // default is 6 MONTH
        lockDuration = 3600 * 24 * 30 * 6;
    }

    modifier phaseRequired(uint8 _phase){
        require(phase == _phase, "Forbidden in phase");
        _;
    }

    // Check address in list Candidate
    modifier onlyCandidate(address candidate){
        bool isValid = false;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i] == candidate) {
                isValid = true;
                break;
            }
        }
        require(isValid == true, "Invalid candidate");
        _;
    }

    modifier onlyGovernance(){
        require(msg.sender == governance, "!governance");
        _;
    }

    modifier checkPhaseRequired(){
        require(phase == 0 || phase == 1, "Only phase 0 or 1");
        _;
    }


    // Get current ranking of candidate
    function getRanking(address candidate) public view returns (uint256 value){
        value = 0;
        if (phase != 2) {
            for (uint256 j = 0; j < candidateVoter[candidate].length; j++) {
                value = value.add(voteResult[candidateVoter[candidate][j]][candidate]);
            }
        } else {
            value = ranking[candidate];
        }
    }

    function setMinDeposit(uint256 _total) onlyGovernance public {
        minDeposit = _total;
    }

    function setMinDelegate(uint256 _total) onlyGovernance public {
        minDelegate = _total;
    }

    function getHolderDetail(address who) external view returns (Detail memory){
        return holderDetail[who];
    }

    function getVoteResult(address who, address candidate) external view returns (uint256){
        return voteResult[who][candidate];
    }

    function getCandidateVoter(address who, uint256 index) external view returns (address){
        return candidateVoter[who][index];
    }

    // Get candidate via index
    function getCandidate(uint256 index) external view returns (address){
        return candidates[index];
    }

    //    // deposit and delegating candidate (only for phase 0,1)
    //    function delegatedDepositAll(address candidate) external onlyCandidate(candidate) checkPhaseRequired {
    //        _deposit(token.balanceOf(msg.sender), candidate);
    //    }

    // deposit and delegating candidate (only for phase 0,1)
    function delegatedDeposit(uint _amount, address candidate) public onlyCandidate(candidate) checkPhaseRequired {
        if (phase == 0) {
            require(ResultVotePhase0[msg.sender] == address(0) && _amount == minDelegate, "Phase 0 only vote once and amount must be equal min delegate");
            ResultVotePhase0[msg.sender] = candidate;
        }
        _deposit(_amount, candidate);
    }

    //    // withdraw and delegating candidate (only for phase 1)
    //    function delegatedWithdrawAll(address candidate) external onlyCandidate(candidate) checkPhaseRequired {
    //        _withdraw(voteResult[msg.sender][candidate], candidate);
    //    }

    // withdraw and delegating candidate (only for phase 0,1)
    function delegatedWithdraw(uint _shares, address candidate) external onlyCandidate(candidate) checkPhaseRequired {
        if (phase == 0) {
            require(ResultVotePhase0[msg.sender] != address(0) && _shares == minDelegate, "Phase 0 withdraw min is 500");
            ResultVotePhase0[msg.sender] = address(0);
        }
        _withdraw(_shares, candidate);
    }

    //    // deposit and self delegating candidate, set detail
    //    function depositAllWithDetail(string calldata name, string calldata website, string calldata description, uint8 commission) external onlyCandidate(msg.sender) {
    //        holderDetail[msg.sender] = Detail(commission, name, website, description);
    //        _deposit(token.balanceOf(msg.sender), msg.sender);
    //    }

    // deposit and self delegating candidate, set detail
    function depositWithDetail(uint _amount, string calldata name, string calldata website, string calldata description, uint8 commission) external onlyCandidate(msg.sender) {
        if (phase == 0) {
            require(ResultVotePhase0[msg.sender] == address(0) && _amount == minDeposit, "Phase 0 only vote once and amount must be equal min deposit");
            ResultVotePhase0[msg.sender] = msg.sender;
        }
        holderDetail[msg.sender] = Detail(commission, name, website, description);
        _deposit(_amount, msg.sender);
    }

    //    // deposit and self delegating candidate
    //    function depositAll() external onlyCandidate(msg.sender) {
    //        _deposit(token.balanceOf(msg.sender), msg.sender);
    //    }

    // deposit and self delegating candidate
    function deposit(uint _amount) public onlyCandidate(msg.sender) {
        if (phase == 0) {
            require(ResultVotePhase0[msg.sender] == address(0) && _amount == minDeposit, "Phase 0 only vote once and amount must be equal min deposit");
            ResultVotePhase0[msg.sender] = msg.sender;
        }
        _deposit(_amount, msg.sender);
    }


    //    // withdraw and self delegating candidate
    //    function withdrawAll() external {
    //        _withdraw(balanceOf(msg.sender), msg.sender);
    //    }

    // withdraw and self delegating candidate
    function withdraw(uint _shares) external {
        if (phase == 0) {
            require(ResultVotePhase0[msg.sender] != address(0) && _shares == minDeposit, "Phase 0 withdraw min is 750");
            ResultVotePhase0[msg.sender] = address(0);
        }
        _withdraw(_shares, msg.sender);
    }


    // set holder Detail
    function setHolderDetail(string memory name, string memory website, string memory description, uint8 commission) public {
        holderDetail[msg.sender] = Detail(commission, name, website, description);
    }

    // get holder Detail



    // set governance
    function setGovernance(address _governance) public onlyGovernance {
        governance = _governance;
    }

    // set lockDuration
    function setLockDuration(uint256 _lockDuration) public onlyGovernance {
        lockDuration = _lockDuration;
    }


    // lock rank result, save rankedResult in ranking variable, then it must run lockErc20
    function lockRanking() external onlyGovernance {
        phase = 2;
        uint256 value;
        for (uint256 i = 0; i < candidates.length; i++) {
            value = 0;
            for (uint256 j = 0; j < candidateVoter[candidates[i]].length; j++) {
                value = value.add(voteResult[candidateVoter[candidates[i]][j]][candidates[i]]);
            }
            ranking[candidates[i]] = value;
        }
    }

    // lock delegatingAddress for list topCandidate, not automatic to avoid out of gas
    function lockErc20(address[] calldata voter, address[] calldata topCandidate) external onlyGovernance {
        uint256 lockedValue;
        for (uint i = 0; i < voter.length; i++) {
            lockedValue = 0;
            for (uint256 j = 0; j < topCandidate.length; j++) {
                lockedValue = lockedValue.add(voteResult[voter[i]][topCandidate[j]]);
            }
            _lock_erc(voter[i], lockedValue);
        }
        timeRelease = block.timestamp + lockDuration;
    }



    // Set phase 0, 1
    function setPhase(uint8 _phase) external onlyGovernance {
        phase = _phase;
    }

    // Set list Candidates
    function setCandidates(address[] calldata _candidates) external phaseRequired(0) onlyGovernance {
        candidates = _candidates;
    }


    // withdraw
    function _withdraw(uint256 _shares, address candidate) internal {
        if (block.timestamp > timeRelease && phase == 2) {
            _unlock_erc(msg.sender);
        }
        _burn(msg.sender, _shares);
        if (phase != 2) {
            if (voteResult[msg.sender][candidate].sub(_shares) == 0) {
                uint256 index = 10 ** 18;
                for (uint256 i = 0; i < candidateVoter[candidate].length; i++) {
                    if (candidateVoter[candidate][i] == msg.sender) {
                        index = i;
                        break;
                    }
                }
                if (index != 10 ** 18) {
                    for (uint256 i = index; i < candidateVoter[candidate].length - 1; i++)
                    {
                        candidateVoter[candidate][i] = candidateVoter[candidate][i + 1];
                    }
                    candidateVoter[candidate].length --;
                }
            }
            voteResult[msg.sender][candidate] = voteResult[msg.sender][candidate].sub(_shares);
        }
        token.safeTransfer(msg.sender, _shares);
    }

    function _deposit(uint256 _amount, address candidate) internal {
        uint _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint _after = token.balanceOf(address(this));
        _amount = _after.sub(_before);
        _mint(msg.sender, _amount);
        if (voteResult[msg.sender][candidate] == 0) {
            candidateVoter[candidate].push(msg.sender);
        }
        voteResult[msg.sender][candidate] = voteResult[msg.sender][candidate].add(_amount);

    }

    function transferOnlyGovernance(address _token, uint256 amount, address _to) onlyGovernance public {
        IERC20(_token).safeTransfer(_to, amount);
    }

    function getBalance(address _token, address account) public view returns (uint256){
        return IERC20(_token).balanceOf(account);
    }

}