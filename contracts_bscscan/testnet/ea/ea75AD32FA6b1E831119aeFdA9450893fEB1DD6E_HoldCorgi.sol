/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract HoldCorgi is Ownable {

    struct TransactionRequest {
        uint256 amount;
        uint256 count;
        bool success;
        address wallet;
    }

    uint256 public minVote;
    IERC20 public Token;
    uint256 private TOKEN_DECIMAL;
    mapping (address => bool) public Adminstrator;
    mapping (uint256 => TransactionRequest) public requests;
    mapping (uint256 => address[]) public votes;

    modifier onlyAdministrator(){
        require(Adminstrator[msg.sender]);
        _;
    }
    
    constructor(address corgitoken){
        minVote = 3;
        Token = IERC20(corgitoken);
        TOKEN_DECIMAL = 10 ** Token.decimals();
        Adminstrator[owner()]= true; // set default admin
    }
    
    function setAdminstrator(address _wallet,bool _isAdministrator) external onlyOwner {
        Adminstrator[_wallet]=_isAdministrator;
    }

    function createRequest(uint256 requestID, uint256 amount, address wallet) external onlyAdministrator {
        require(requests[requestID].amount == 0, "Request exists");
        TransactionRequest memory transaction = TransactionRequest(
            amount,
            1,
            false,
            wallet
        );
        votes[requestID].push(msg.sender);
        requests[requestID] = transaction;
    }

    function voteRequest(uint256 requestID) external onlyAdministrator {
        require(requests[requestID].amount > 0, "Request inexists");
        uint256 withdrawBalance = requests[requestID].amount * TOKEN_DECIMAL;
        address withdrawWallet = requests[requestID].wallet;
        require(checkVote(requestID,msg.sender) == false, "is voted");
        require(Token.balanceOf(address(this)) > withdrawBalance,"Not enough token.");
        require(requests[requestID].success == false, "Request is finish");
        requests[requestID].count += 1;
        if(requests[requestID].count == minVote){
            requests[requestID].success = true;
            Token.transfer(withdrawWallet, withdrawBalance);
        }
    }

    function setminVote(uint256 _min) external onlyOwner{
        minVote = _min;
    }

    function getRequest(uint256 requestID) external view returns (TransactionRequest memory){
        return requests[requestID];
    }

    function checkVote(uint256 requestID, address admin) internal view returns (bool){
        require(votes[requestID].length > 0);
        bool result = false;
        for(uint256 i=0;i < votes[requestID].length; i++){
            if(votes[requestID][i] == admin){
                result = true;
            }
        }
        return result;
    }
}