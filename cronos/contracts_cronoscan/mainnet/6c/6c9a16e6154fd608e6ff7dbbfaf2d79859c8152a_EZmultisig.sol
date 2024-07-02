/**
 *Submitted for verification at cronoscan.com on 2022-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract MjolnirRBAC {
    mapping(address => bool) internal _thors;

    modifier onlyThor() {
        require(
            _thors[msg.sender] == true || address(this) == msg.sender,
            "Caller cannot wield Mjolnir"
        );
        _;
    }

    function addThor(address _thor)
        external
        onlyOwner
    {
        _thors[_thor] = true;
    }

    function delThor(address _thor)
        external
        onlyOwner
    {
        delete _thors[_thor];
    }

    function disableThor(address _thor)
        external
        onlyOwner
    {
        _thors[_thor] = false;
    }

    function isThor(address _address)
        external
        view
        returns (bool allowed)
    {
        allowed = _thors[_address];
    }

    function toAsgard() external onlyThor {
        delete _thors[msg.sender];
    }
    //Oracle-Role
    mapping(address => bool) internal _oracles;

    modifier onlyOracle() {
        require(
            _oracles[msg.sender] == true || address(this) == msg.sender,
            "Caller is not the Oracle"
        );
        _;
    }

    function addOracle(address _oracle)
        external
        onlyOwner
    {
        _oracles[_oracle] = true;
    }

    function delOracle(address _oracle)
        external
        onlyOwner
    {
        delete _oracles[_oracle];
    }

    function disableOracle(address _oracle)
        external
        onlyOwner
    {
        _oracles[_oracle] = false;
    }

    function isOracle(address _address)
        external
        view
        returns (bool allowed)
    {
        allowed = _oracles[_address];
    }

    function relinquishOracle() external onlyOracle {
        delete _oracles[msg.sender];
    }
    //Ownable-Compatability
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    //contextCompatability
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract EZmultisig is MjolnirRBAC {

        struct Proposals {
        uint256 amount;
		uint256 votes;
        uint256 anti;
        address asset;
        address initiator;
        address reciever;
        bool complete;
        string reason;
    }

        struct Secure {
        uint256 atProp;
        bool didVote;
        }

    mapping(uint256 => Proposals) pro;
    mapping(address => Secure) sec;

    uint256 public currProposal = 0;

    function issueProposal(uint256 value, address recieverAddr, address token, string memory reasoning) external onlyThor {
        if(currProposal != 0){require(pro[currProposal].complete == true);}
        currProposal++;
        pro[currProposal].amount = value;
        pro[currProposal].asset = token;
        pro[currProposal].votes = 1;
        pro[currProposal].initiator = msg.sender;
        pro[currProposal].reciever = recieverAddr;
        pro[currProposal].complete = false;
        pro[currProposal].reason = reasoning;
        sec[msg.sender].didVote = true;
    }

    function voteYes() external onlyThor {
    require(sec[msg.sender].didVote == false);
    require(pro[currProposal].complete == false);
    sec[msg.sender].atProp = currProposal;
    sec[msg.sender].didVote = true;
    pro[currProposal].votes = pro[currProposal].votes++;
    if(pro[currProposal].votes >= 3){execute();}
    }

    function voteNo() external onlyThor {
    require(sec[msg.sender].didVote == false);
    require(pro[currProposal].complete == false);
    sec[msg.sender].atProp = currProposal;
    sec[msg.sender].didVote = true;
    pro[currProposal].anti = pro[currProposal].anti++;
    if(pro[currProposal].anti >= 3){skipProp();}
    }

    function execute() internal {
    address token = pro[currProposal].asset;
    IERC20 tk = IERC20(token);
    tk.transfer(pro[currProposal].reciever,pro[currProposal].amount);
    pro[currProposal].complete = true;
    }

    function skipProp() internal {
    pro[currProposal].complete = true;
    }

    function depoTokens(uint256 value, address token) external {
    IERC20 tk = IERC20(token);
    tk.transferFrom(msg.sender,address(this),value);
    }

    function tokenBalance(address token) external view returns(uint256) {
    IERC20 tk = IERC20(token);
    return tk.balanceOf(address(this));
    }
}