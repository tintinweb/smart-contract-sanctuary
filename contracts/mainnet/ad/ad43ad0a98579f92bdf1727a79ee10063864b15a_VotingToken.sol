/**
 *Submitted for verification at Etherscan.io on 2021-02-20
*/

pragma solidity ^0.6.0;

interface IMVDProxy {

    function init(address votingTokenAddress, address functionalityProposalManagerAddress, address stateHolderAddress, address functionalityModelsManagerAddress, address functionalitiesManagerAddress, address walletAddress, address doubleProxyAddress) external;

    function getDelegates() external view returns(address[] memory);
    function getToken() external view returns(address);
    function getMVDFunctionalityProposalManagerAddress() external view returns(address);
    function getStateHolderAddress() external view returns(address);
    function getMVDFunctionalityModelsManagerAddress() external view returns(address);
    function getMVDFunctionalitiesManagerAddress() external view returns(address);
    function getMVDWalletAddress() external view returns(address);
    function getDoubleProxyAddress() external view returns(address);
    function setDelegate(uint256 position, address newAddress) external returns(address oldAddress);
    function changeProxy(address newAddress, bytes calldata initPayload) external;
    function isValidProposal(address proposal) external view returns (bool);
    function newProposal(string calldata codeName, bool emergency, address sourceLocation, uint256 sourceLocationId, address location, bool submitable, string calldata methodSignature, string calldata returnParametersJSONArray, bool isInternal, bool needsSender, string calldata replaces) external returns(address proposalAddress);
    function startProposal(address proposalAddress) external;
    function disableProposal(address proposalAddress) external;
    function transfer(address receiver, uint256 value, address token) external;
    function transfer721(address receiver, uint256 tokenId, bytes calldata data, bool safe, address token) external;
    function flushToWallet(address tokenAddress, bool is721, uint256 tokenId) external;
    function setProposal() external;
    function read(string calldata codeName, bytes calldata data) external view returns(bytes memory returnData);
    function submit(string calldata codeName, bytes calldata data) external payable returns(bytes memory returnData);
    function callFromManager(address location, bytes calldata payload) external returns(bool, bytes memory);
    function emitFromManager(string calldata codeName, address proposal, string calldata replaced, address replacedSourceLocation, uint256 replacedSourceLocationId, address location, bool submitable, string calldata methodSignature, bool isInternal, bool needsSender, address proposalAddress) external;

    function emitEvent(string calldata eventSignature, bytes calldata firstIndex, bytes calldata secondIndex, bytes calldata data) external;

    event ProxyChanged(address indexed newAddress);
    event DelegateChanged(uint256 position, address indexed oldAddress, address indexed newAddress);

    event Proposal(address proposal);
    event ProposalCheck(address indexed proposal);
    event ProposalSet(address indexed proposal, bool success);
    event FunctionalitySet(string codeName, address indexed proposal, string replaced, address replacedSourceLocation, uint256 replacedSourceLocationId, address indexed replacedLocation, bool replacedWasSubmitable, string replacedMethodSignature, bool replacedWasInternal, bool replacedNeededSender, address indexed replacedProposal);

    event Event(string indexed key, bytes32 indexed firstIndex, bytes32 indexed secondIndex, bytes data);
}

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

interface IVotingToken {
    function init(string calldata name, string calldata symbol, uint256 decimals, uint256 totalSupply) external;

    function getProxy() external view returns (address);
    function setProxy() external;

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint256);

    function mint(uint256 amount) external;
    function burn(uint256 amount) external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

interface IMVDFunctionalityProposalManager {
    function newProposal(string calldata codeName, address location, string calldata methodSignature, string calldata returnAbiParametersArray, string calldata replaces) external returns(address);
    function checkProposal(address proposalAddress) external;
    function getProxy() external view returns (address);
    function setProxy() external;
    function isValidProposal(address proposal) external view returns (bool);
}

interface IMVDFunctionalitiesManager {

    function getProxy() external view returns (address);
    function setProxy() external;

    function init(address sourceLocation,
        uint256 getMinimumBlockNumberSourceLocationId, address getMinimumBlockNumberFunctionalityAddress,
        uint256 getEmergencyMinimumBlockNumberSourceLocationId, address getEmergencyMinimumBlockNumberFunctionalityAddress,
        uint256 getEmergencySurveyStakingSourceLocationId, address getEmergencySurveyStakingFunctionalityAddress,
        uint256 checkVoteResultSourceLocationId, address checkVoteResultFunctionalityAddress) external;

    function addFunctionality(string calldata codeName, address sourceLocation, uint256 sourceLocationId, address location, bool submitable, string calldata methodSignature, string calldata returnAbiParametersArray, bool isInternal, bool needsSender) external;
    function addFunctionality(string calldata codeName, address sourceLocation, uint256 sourceLocationId, address location, bool submitable, string calldata methodSignature, string calldata returnAbiParametersArray, bool isInternal, bool needsSender, uint256 position) external;
    function removeFunctionality(string calldata codeName) external returns(bool removed, uint256 position);
    function isValidFunctionality(address functionality) external view returns(bool);
    function isAuthorizedFunctionality(address functionality) external view returns(bool);
    function setCallingContext(address location) external returns(bool);
    function clearCallingContext() external;
    function getFunctionalityData(string calldata codeName) external view returns(address, uint256, string memory, address, uint256);
    function hasFunctionality(string calldata codeName) external view returns(bool);
    function getFunctionalitiesAmount() external view returns(uint256);
    function functionalitiesToJSON() external view returns(string memory);
    function functionalitiesToJSON(uint256 start, uint256 l) external view returns(string memory functionsJSONArray);
    function functionalityNames() external view returns(string memory);
    function functionalityNames(uint256 start, uint256 l) external view returns(string memory functionsJSONArray);
    function functionalityToJSON(string calldata codeName) external view returns(string memory);

    function preConditionCheck(string calldata codeName, bytes calldata data, uint8 submitable, address sender, uint256 value) external view returns(address location, bytes memory payload);

    function setupFunctionality(address proposalAddress) external returns (bool);
}

contract VotingToken is IERC20, IVotingToken {

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _decimals;
    address private _proxy;
    string private _name;
    string private _symbol;

    constructor(string memory name, string memory symbol, uint256 decimals, uint256 totalSupply) public {
        if(totalSupply == 0) {
            return;
        }
        init(name, symbol, decimals, totalSupply);
    }

    function init(string memory name, string memory symbol, uint256 decimals, uint256 totalSupply) public override {
        require(_totalSupply == 0, "Init already called!");

        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = totalSupply * (10 ** decimals);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(this), msg.sender, _totalSupply);
    }

    receive() external payable {
        revert("ETH not accepted");
    }

    function getProxy() public override view returns(address) {
        return _proxy;
    }

    function name() public override view returns(string memory) {
        return _name;
    }

    function symbol() public override view returns(string memory) {
        return _symbol;
    }

    function decimals() public override view returns(uint256) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        address txSender = msg.sender;
        if(_proxy == address(0) || !(IMVDFunctionalityProposalManager(IMVDProxy(_proxy).getMVDFunctionalityProposalManagerAddress()).isValidProposal(txSender) && recipient == txSender)) {
            _approve(sender, txSender, _allowances[sender][txSender] = sub(_allowances[sender][txSender], amount, "ERC20: transfer amount exceeds allowance"));
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        _approve(msg.sender, spender, add(_allowances[msg.sender][spender], addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        _approve(msg.sender, spender, sub(_allowances[msg.sender][spender], subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = sub(_balances[sender], amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = add(_balances[recipient], amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256 c) {
        require(b <= a, errorMessage);
        c = a - b;
    }

    function setProxy() public override {
        require(_totalSupply != 0, "Init not called!");
        require(_proxy == address(0) || _proxy == msg.sender, _proxy != address(0) ? "Proxy already set!" : "Only Proxy can toggle itself!");
        _proxy = _proxy == address(0) ?  msg.sender : address(0);
    }

    function mint(uint256 amount) public override {
        require(IMVDFunctionalitiesManager(IMVDProxy(_proxy).getMVDFunctionalitiesManagerAddress()).isAuthorizedFunctionality(msg.sender), "Unauthorized access!");

        _totalSupply = add(_totalSupply, amount);
        _balances[_proxy] = add(_balances[_proxy], amount);
        emit Transfer(address(0), _proxy, amount);
    }

    function burn(uint256 amount) public override {
        _balances[msg.sender] = sub(_balances[msg.sender], amount, "VotingToken: burn amount exceeds balance");
        _totalSupply = sub(_totalSupply, amount, "VotingToken: burn amount exceeds total supply");
        emit Transfer(msg.sender, address(0), amount);
    }
}