/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.4.25;
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
contract relationship is Ownable{
    
    address defultFather;
    mapping(address => address) public father;
    mapping(address => address) public grandFather;
    mapping(address => bool) public callSetRelationshipAddress;//可以设置除自己外地址的推荐人的特权地址
    
    modifier callSetRelationship(){
        require(callSetRelationshipAddress[msg.sender] == true,"can't set relationship!");
        _;
    }

    function init(address _defultFather, address _airDrop, address _buy) public onlyOwner(){
        defultFather = _defultFather;//默认推荐人，在没有其他推荐人的情况下，一二代推荐人都是他
        setCallSetRelationshipAddress(_airDrop, true);
        setCallSetRelationshipAddress(_buy, true);
    }
    
    function _setRelationship(address _son, address _father) internal {
        require(_son != _father,"Father cannot be himself!");//推荐人不能是他自己
        if (father[_son] != address(0)){//推荐人如果已经存在 直接返回，这里是为了满足购买调用时绑定推荐人关系，如果推荐人已经存在了，就直接返回，不做任何操作
            return;
        }
        address _grandFather = getFather(_father);
        
        father[_son] = _father;
        grandFather[_son] = _grandFather;
    }

    function setRelationship(address _father) public {
        _setRelationship(msg.sender, _father);
    }

    function otherCallSetRelationship(address _son, address _father) public callSetRelationship() {
        _setRelationship(_son, _father);
    }
    
    function getFather(address _addr) public view returns(address){
        return father[_addr] != address(0) ? father[_addr] : defultFather;
    }
    function getGrandFather(address _addr) public view returns(address){
        return grandFather[_addr] != address(0) ? grandFather[_addr] : defultFather;
    }
    
    //****************************************//
    //*
    //* admin function
    //*
    //****************************************//
    
    function setDefultFather(address _addr) public onlyOwner() {
        require(msg.sender == defultFather);
        defultFather = _addr;
    }

    function setCallSetRelationshipAddress(address _addr, bool no_yes) public onlyOwner(){
        callSetRelationshipAddress[_addr] = no_yes;
    }
}