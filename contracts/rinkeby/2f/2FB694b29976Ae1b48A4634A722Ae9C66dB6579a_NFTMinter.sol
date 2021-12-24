// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./access/MedievalAccessControlled.sol";
import "./interface/IMedievalNFT.sol";
import "./interface/IMedievalToken.sol";

contract NFTMinter is MedievalAccessControlled{
    IMedievalNFT immutable nft;
    IMedievalToken immutable food;

    uint256 FOOD_RAIO_UNIT = 10 ** 18;

    struct Price {
        uint256 ethAmount;
        uint256 foodRatio;
        uint256 counter;
    }

    mapping(uint256 => Price) tokenPrice;

    constructor(
        address _controlCenter,
        address _nft,
        address _food
    ){
        _setControlCenter(_controlCenter, msg.sender);
        nft = IMedievalNFT(_nft);
        food = IMedievalToken(_food);
    }

    function mint(uint256 occupation) external payable{
        Price storage price = tokenPrice[occupation];
        require(price.counter > 0, "This occupation has been sold out!");
        require(msg.value == price.ethAmount, "Incorrect ETH Amount");

        payable(_dao()).transfer(msg.value);
        
        if(price.foodRatio > 0) {
            uint256 amount = foodAmount(price.foodRatio);
            food.transferFrom(msg.sender, address(this), amount);
            food.burn(amount);
        }
        nft.mint(msg.sender, occupation);
        price.counter -= 1;
    }

    function foodAmount(uint256 _foodRatio) public view returns(uint256) {
        return _foodRatio * food.totalSupply() / FOOD_RAIO_UNIT;
    }

    function setPrice(uint256 occupation, 
        uint256 ethAmount, uint256 foodRatio, uint256 counter) external onlyAdmin {
            tokenPrice[occupation] = Price(
                ethAmount, foodRatio, counter
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.7.0;
import "./interface/IMedievalAccessControlCenter.sol";

contract MedievalAccessControlled {   
    string constant ACCESS_DENIED_MSG = "Access Denied!"; 
    
    bytes32 constant DEFAULT_ADMIN_ROLE = 0;

    IMedievalAccessControlCenter public controlCenter;
    
    // tempAdmin has all the priviledge, and it is only used when controlCenter is not set.
    address public tempAdmin; 

    function _setControlCenter(address _controlCenter, address _tempAdmin) internal {
        controlCenter = IMedievalAccessControlCenter(_controlCenter);
        if(_controlCenter == address(0)){
            tempAdmin =_tempAdmin;
        } else {
            tempAdmin = address(0);
            // Prevent setting controlCenter to an invalid address.
            require(
                controlCenter.getRoleMemberCount(DEFAULT_ADMIN_ROLE) > 0,
                "Invalid controlCenter address!"
            ); 
        }
    }

    function setControlCenter(address _controlCenter, address _tempAdmin) external onlyAdmin {
        _setControlCenter(_controlCenter, _tempAdmin);
    }

    function _hasRole(bytes32 role, address account) internal view returns(bool){
        return controlCenter.hasRole(role, account);
    }

    function _treasury() internal view returns(address){
        return controlCenter.treasury();
    }

    function _dao() internal view returns(address){
        return controlCenter.dao();
    }

    modifier onlyRole(bytes32 role) {
        if(address(controlCenter) == address(0)) {
            require(tempAdmin == msg.sender, ACCESS_DENIED_MSG);
        } else {
            require(_hasRole(role, msg.sender),
                ACCESS_DENIED_MSG);
        }
        _;
    }

    modifier onlyAdmin() {
        if(address(controlCenter) == address(0)) {
            require(tempAdmin == msg.sender, ACCESS_DENIED_MSG);
        } else {
            require(_hasRole(0, msg.sender),
                ACCESS_DENIED_MSG);
        }
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >0.7.0;

interface IMedievalAccessControlCenter {
  function addressBook ( bytes32 ) external view returns ( address );
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function getRoleMember ( bytes32 role, uint256 index ) external view returns ( address );
  function getRoleMemberCount ( bytes32 role ) external view returns ( uint256 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function renounceRole ( bytes32 role, address account ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function setAddress ( bytes32 id, address _address ) external;
  function setRoleAdmin ( bytes32 role, bytes32 adminRole ) external;
  function treasury (  ) external view returns ( address );
  function dao (  ) external view returns ( address );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMedievalNFT {
    function setMinter(address _minte) external;
    function mint(address to, uint256 occupation) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMedievalToken {
  function DOMAIN_SEPARATOR (  ) external view returns ( bytes32 );
  function PERMIT_TYPEHASH (  ) external view returns ( bytes32 );
  function _burnFrom ( address account_, uint256 amount_ ) external;
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address account ) external view returns ( uint256 );
  function burn ( uint256 amount ) external;
  function burnFrom ( address account_, uint256 amount_ ) external;
  function controlCenter (  ) external view returns ( address );
  function decimals (  ) external view returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function mint ( address account_, uint256 amount_ ) external;

  function nonces ( address owner ) external view returns ( uint256 );
  function permit ( address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s ) external;
  function setControlCenter ( address _controlCenter, address _tempAdmin ) external;

  function tempAdmin (  ) external view returns ( address );
  function totalSupply (  ) external view returns ( uint256 );
  function transfer ( address recipient, uint256 amount ) external returns ( bool );
  function transferFrom ( address sender, address recipient, uint256 amount ) external returns ( bool );
}