/**
 *Submitted for verification at polygonscan.com on 2021-11-19
*/

// Sources flattened with hardhat v2.6.2 https://hardhat.org

// File contracts/EasyWrapper.sol

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;


interface CToken{
  function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
}

interface IComptroller{
  function checkMembership(address user,address eToken) external view returns (bool);
  function compAccrued(address user) external view returns (uint);
}

contract WrapperContract{

    address public owner;
    //Structure of user's market info
    
    address[] public markets;
    address comptroller;//Comptroller address
    
    struct UserInfo  {
     uint suppliedBalance;
     uint borrowedBalance;
     bool entered;
     uint exchangeRate;
     address eTokenAddress;
    }

    //Validation so only admin can add markets
    modifier onlyOwner{
      require(msg.sender == owner);
      _;
    }

    constructor(address _comptroller) public{
        owner = msg.sender;
        comptroller = _comptroller;
    }

    /**
     * @notice Adds supported markets to the wrapper contract.
     * @param eToken Addresses of token markets
     */
    function addMarkets(address[] memory eToken) public onlyOwner{
        for(uint i=0; i<eToken.length;i++){
         markets.push(eToken[i]);
        }
    }

    /**
     * @notice Gets user info from all the supported market contracts
     * @param user Address of user
     */
    function getUserDetails(address user) public view returns (UserInfo[] memory, uint){
        UserInfo[] memory userDetails = new UserInfo[](markets.length);
        for(uint i=0;i<markets.length;i++){
          (uint error, uint balance, uint borrowBalance, uint _exchangeRate) = CToken(markets[i]).getAccountSnapshot(user);
          UserInfo memory userInfo = UserInfo({suppliedBalance: balance, borrowedBalance: borrowBalance, entered: IComptroller(comptroller).checkMembership(user,markets[i]), exchangeRate: _exchangeRate, eTokenAddress: markets[i]});
          userDetails[i] = userInfo;
        }
        uint compAccrued = IComptroller(comptroller).compAccrued(user);
        return (userDetails, compAccrued);
    }

}