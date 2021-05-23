/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.4.25;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
interface relationship {
    function father(address _son) external view returns(address);
    function otherCallSetRelationship(address _son, address _father) external;
    function getFather(address _addr) external view returns(address);
    function getGrandFather(address _addr) external view returns(address);
}
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view  returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public  onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract airDrop is Ownable{
    IERC20 token;
    relationship RP;
    
    mapping(address => bool) public users;
    uint256 airAmount;
    
    function init(address _token, uint256 _airAmount, address _rp) public onlyOwner() {
        token = IERC20(_token);
        airAmount =_airAmount;
        RP = relationship(_rp);
    }

    function getair() public returns(uint256) {
        return _getair(msg.sender);
    }

    function getair(address _reff) public returns (uint256){
        if (RP.father(msg.sender) == address(0)){
            RP.otherCallSetRelationship(msg.sender, _reff);
        }
         return _getair(msg.sender);
    }

    function _getair(address _sender) internal returns(uint256){
        require(users[_sender] == false, "has getair!");


        address father = RP.getFather(_sender);
        address grandFather = RP.getGrandFather(_sender);

        token.transfer(father, airAmount / 10);
        token.transfer(grandFather, airAmount / 20);
        token.transfer(_sender, airAmount);
        users[_sender] = true;
        return airAmount;
    }
}