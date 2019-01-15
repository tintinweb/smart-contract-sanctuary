pragma solidity > 0.4.99 <0.6.0;

interface IPayeeShare {
    function payeePartsToSell() external view returns (uint256);
    function payeePricePerPart() external view returns (uint256);
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract AssetSplitContracts {
    
     struct Contract {
        address payable contractAddress;
        address payable creatorAddress;
        uint256 contractType;
        uint256 a_uint256;
        string a_string;
        uint256 b_uint256;
        string b_string;
        uint256 c_uint256;
        string c_string;
        bool active;
    }
    
    Contract[] public contracts;

    struct SaleContract {
        address payable saleContractAddress;
    }
    
    SaleContract[] public saleContracts;
    
    mapping (address => uint) public saleContractCount;
    
    string public constant createdBy = "AssetSplit.org - the guys who cut the pizza";
    
    event AddedContract(address contractAddress, address contractCreator, uint256 contractType);
    
    bytes32 password = 0x75673d0f21e100acda4f6dc8b3ac99a142af1d843cb1936898d854e930409f10;

    using SafeMath for uint256;
    
    function addSaleContract(address payable _contractAddress, string memory _password, bytes32 _newPassword) public {
        bytes32 pw = keccak256(bytes(_password));
        require(password == pw);
        require(password != _newPassword);
        password = _newPassword;
        saleContracts.push(SaleContract(_contractAddress)).sub(1);
        saleContractCount[_contractAddress] = saleContractCount[_contractAddress].add(1);
    }
    
    function editSaleContract(uint _id, address payable _newContractAddress, string memory _password, bytes32 _newPassword) public {
        bytes32 pw = keccak256(bytes(_password));
        require(password == pw);
        require(_newPassword != "");
        password = _newPassword;
        SaleContract storage myContract = saleContracts[_id];
        myContract.saleContractAddress = _newContractAddress;
        saleContractCount[_newContractAddress] = saleContractCount[_newContractAddress].add(1);
    }
    
    function addContract(address payable _contractAddress, address payable _creatorAddress, uint256 _contractType) public returns (bool success) {
        require (saleContractCount[msg.sender] > 0);
        removeOldFirst(_contractAddress);
        contracts.push(Contract(_contractAddress, _creatorAddress, _contractType, 0, "", 0, "", 0, "", true));
        emit AddedContract(_contractAddress, _creatorAddress, _contractType);
        return true;
    }

    function editContract (uint _id, uint256 _a_uint256, string memory _a_string, uint256 _b_uint256, string memory _b_string, uint256 _c_uint256, string memory _c_string) public returns (bool success) {
        require (saleContractCount[msg.sender] > 0);
        Contract storage myContract = contracts[_id];
        myContract.a_uint256 = _a_uint256;
        myContract.a_string = _a_string;
        myContract.b_uint256 = _b_uint256;
        myContract.b_string = _b_string;
        myContract.c_uint256 = _c_uint256;
        myContract.c_string = _c_string;
        return true;
    }
    
    function removeOldFirst(address _contractAddress) internal {
        for (uint i = 0; i < contracts.length; i++) {    
            Contract storage myContracts = contracts[i];
            if (myContracts.contractAddress == _contractAddress) {
                myContracts.active = false;
            }
        }
    }
    
    function countActiveType(uint256 _type) internal view returns (uint256) {
        uint256 counter = 0;
        for (uint i = 0; i < contracts.length; i++) {
            Contract memory myContracts = contracts[i];
        if (myContracts.contractType == _type && myContracts.active == true) {
            counter++;
          }
        }
        return counter;
    }
    
   function getContractsByType(uint256 _type) public view returns (uint[] memory) {
        uint[] memory result = new uint[](countActiveType(_type));
        uint counter = 0;
        for (uint i = 0; i < contracts.length; i++) {
            Contract memory myContracts = contracts[i];
          if (myContracts.contractType == _type && myContracts.active == true) {
            result[counter] = i;
            counter++;
          }
        }
        return result;
    }
  
     function getMyContractsByType(uint256 _type) public view returns (uint[] memory) {
        uint[] memory result = new uint[](countActiveType(_type));
        uint counter = 0;
        for (uint i = 0; i < contracts.length; i++) {
        Contract memory myContracts = contracts[i];
          if (myContracts.contractType == _type && myContracts.creatorAddress == msg.sender && myContracts.active == true) {
            result[counter] = i;
            counter++;
          }
        }
        return result;
    }
    
    function cleanSellShareOutput() public {
        for (uint i = 0; i < contracts.length; i++) {    
            Contract storage myContracts = contracts[i];
            IPayeeShare shareContract;
            shareContract = IPayeeShare(myContracts.contractAddress);
            if (shareContract.payeePartsToSell() < 1 || shareContract.payeePricePerPart() == 0) {
                myContracts.active = false;
            }
        }
    }
    

}