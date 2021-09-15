/**
 *Submitted for verification at polygonscan.com on 2021-09-15
*/

// File: contracts/SafeMath.sol

pragma solidity ^0.5.0;


library SafeMath {

  
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/IBEP20.sol

pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/Referral.sol

pragma solidity ^0.5.0;



/**
 * @title Referral
 * @dev On-chain Referral System.
 */
contract Referral{
    using SafeMath for uint256;
    struct affiliateDetails {
        string ownerId;
        address ownerAddress;
        uint256 percentage;
    }
    mapping(uint256 => affiliateDetails) affiliate;
    address private nftDEX;
    uint256 referralIDCount;
    
    mapping (uint256 => uint256) _referralCodeByToken;
    mapping (uint256 => referralCodeDetails) refferer;
    struct reffererDetails{
        address reffererAddress;
        string reffererId;
    }
    struct referralCodeDetails{
        bool isExpired;
        uint256 count;
       mapping (bytes4 => reffererDetails) _referralCodes;
    }
    mapping (bytes4 => uint256) tokenIdByRefferalCode;
    mapping (address => mapping(string => bytes4)) referralCodeByUser;
    mapping (uint256 => mapping(uint256 => bytes4)) referralCodesByTokenId;

    function init() public {
        nftDEX = 0xC84E3F06Ae0f2cf2CA782A1cd0F653663c99280d;
    }
    
    function convertBytesToBytes8() internal returns (bytes4) {
        bytes4 outBytes8;
        bytes memory inBytes = abi.encodePacked(keccak256(abi.encode(block.number, msg.data, ++referralIDCount)));
        uint256 maxByteAvailable = inBytes.length < 4 ? inBytes.length : 4;
        for (uint256 i = 0; i < maxByteAvailable; i++) {
        bytes4 tempBytes8 = inBytes[i];
        tempBytes8 = tempBytes8 >> (4 * i);
        outBytes8 = outBytes8 | tempBytes8;
    }
}
    modifier nftDexContract() {
        require(msg.sender == nftDEX);
        _;
    }
/**
    * @dev Registers new referree.
    * @param _reffererID The ID of Referrer.
    */
    function referereRegister(uint256 _tokenId, string memory _reffererID ) public {
        require(affiliate[_tokenId].percentage > 0,"not added to affiliate");
        bytes4 _referralCode = convertBytesToBytes8();
        refferer[_tokenId].isExpired = false;
        refferer[_tokenId]._referralCodes[_referralCode].reffererId = _reffererID;
        refferer[_tokenId]._referralCodes[_referralCode].reffererAddress = msg.sender;
        referralCodeByUser[msg.sender][_reffererID]=_referralCode;
        referralCodesByTokenId[_tokenId][refferer[_tokenId].count] = _referralCode;
        refferer[_tokenId].count += 1;
        tokenIdByRefferalCode[_referralCode]= _tokenId;

        emit NewReferral(_tokenId, msg.sender, _referralCode, _reffererID, false);
    }

    function addAffiliate(uint256 _tokenId, string calldata _ownerId, uint256 _percentage, address _ownerAddress)nftDexContract  external {
        require(_percentage > 0);
        affiliate[_tokenId].percentage = _percentage;
        affiliate[_tokenId].ownerAddress = _ownerAddress;
        affiliate[_tokenId].ownerId = _ownerId;
        emit NewAffiliate(_tokenId, _ownerId, _percentage);
    }

    function referralUsed(uint256 _tokenId, bytes4 referralCode) nftDexContract external {
        require(tokenIdByRefferalCode[referralCode] == _tokenId && !refferer[_tokenId].isExpired);
        refferer[_tokenId].isExpired = true;
        delete affiliate[_tokenId];
        emit ReferralCodeUsed(_tokenId, referralCode);
        for(uint256 i =0; i <refferer[_tokenId].count; i++){
            bytes4 temp = referralCodesByTokenId[_tokenId][i];
            delete referralCodeByUser[refferer[_tokenId]._referralCodes[temp].reffererAddress][refferer[_tokenId]._referralCodes[temp].reffererId];
            delete refferer[_tokenId]._referralCodes[temp];
            delete  tokenIdByRefferalCode[temp];
            delete referralCodesByTokenId[_tokenId][i];
            
        }
        
    }

    function getAffiliaTeDetails(uint256 _tokenId) public view returns(uint256, string memory) {
        return(affiliate[_tokenId].percentage, affiliate[_tokenId].ownerId);
    }
    function getReffererDetails(uint256 tokenId, bytes4 referralCode) public view returns(address,string memory, bool, uint256) {
        return(refferer[tokenId]._referralCodes[referralCode].reffererAddress,refferer[tokenId]._referralCodes[referralCode].reffererId,refferer[tokenId].isExpired,affiliate[tokenId].percentage);
    }

    function getRefferalCode(address _ownerAddress, string memory ownerId) public view returns(bytes4){
        return referralCodeByUser[_ownerAddress][ownerId];
    }


    event NewReferral(uint256 indexed tokenId, address indexed referee, bytes4 indexed referralCode, string refereeId, bool isExpired);
    event NewAffiliate( uint256 indexed tokenId, string ownerId, uint256 percentage);
    event ReferralCodeUsed(uint256 tokenId, bytes4 referralCode);
    // event ReferralBonus(address indexed referee, address indexed referrer, uint256 bonus, address token);

}