pragma solidity ^0.4.18;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract SELabel is Ownable {
    string score;
    SeLabelTypes.seType labelType;
    // constructor
    constructor(string _score, SeLabelTypes.seType _type) public {
        score = _score;
        labelType = _type;
    }

    function setScore(string _score) public onlyOwner {
        score = _score;
    }

    function getSEScore() public view returns(string){
        return score;
    }
    
    function getLabelType() public view returns(SeLabelTypes.seType){
        return labelType;
    }
}

library SeLabelTypes {
    enum seType {
        PersonalValue, 
        MasterSheetValue, 
        ModernSlavery
    }
}

contract PassportID is Ownable{
    // list of SeLabels that the owner has.
    SELabel[] public mySELabels;
    // name of the owner
    string public name;
    constructor (string _name, SELabel[] _seLabels) public{
        name = _name;
        mySELabels = _seLabels;
    }

    // add a new selabel to the selabels list.
    function addNewSELabel(SELabel _seLabel) public onlyOwner {
        SeLabelTypes.seType label = _seLabel.getLabelType();
        for(uint8 i = 0; i < mySELabels.length; i++){
            if(label == mySELabels[i].getLabelType()){
                revert();
            }
        }
        mySELabels.push(_seLabel);
    }
 
    // Remove an SE label from the SELabels list
    function removeSELabel(SELabel _seLabel) public onlyOwner {
        for(uint8 i = 0; i < mySELabels.length; i++){
            if(mySELabels[i] == _seLabel){
                mySELabels[i] = mySELabels[mySELabels.length - 1];
                delete(mySELabels[mySELabels.length - 1]);
                mySELabels.length--;
                break;
            }
        }
    }

    function isExisted(SELabel _seLabel) public view returns(bool){
        for(uint8 i = 0; i < mySELabels.length; i++){
            if(mySELabels[i] == _seLabel){
                return true;
            }
        }
        return false;
    }
    // SETTER

    function setName(string _name) public onlyOwner{
        name = _name;
    }

    function setSELabels(SELabel[] _mySELabels) public onlyOwner{
        mySELabels = _mySELabels;
    } 

    function getSELabels() public view returns(SELabel[]){
        return mySELabels;
    }
}

contract Registry is Ownable{
    mapping(address => PassportID) public registry;
    constructor() public {

    }
    function addRecord(PassportID _passport, address _address) public onlyOwner {
        registry[_address] = _passport;
    }

    function getPassportId(address _address) public view returns(PassportID){
        return registry[_address];
    }
}