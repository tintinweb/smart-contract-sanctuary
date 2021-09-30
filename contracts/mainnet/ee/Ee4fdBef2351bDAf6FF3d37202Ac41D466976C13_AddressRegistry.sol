//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT


import "./utils/Admin.sol";

/** @title Paladin AddressRegistry  */
/// @author Paladin
contract AddressRegistry is Admin {

    address private controller;

    address private loanToken;

    //underlying -> palPool
    mapping(address => address) private palPools;

    //underlying -> palToken
    mapping(address => address) private palTokens;

    //palPool -> palToken
    mapping(address => address) private palTokensByPool;



    constructor(
        address _controller,
        address _loanToken,
        address[] memory _underlyings,
        address[] memory _pools,
        address[] memory _tokens
    ) {
        admin = msg.sender;

        controller = _controller;
        loanToken = _loanToken;

        for(uint i = 0; i < _pools.length; i++){
            palPools[_underlyings[i]] = _pools[i];
            palTokens[_underlyings[i]] = _tokens[i];
            palTokensByPool[_pools[i]] = _tokens[i];
        }
    }


    /**
    * @notice Get the Paladin controller address
    * @return address : address of the controller
    */
    function getController() external view returns(address){
        return controller;
    }

    /**
    * @notice Get the PalLoanToken contract address
    * @return address : address of the PalLoanToken contract
    */
    function getPalLoanToken() external view returns(address){
        return loanToken;
    }

    /**
    * @notice Return the PalPool linked to a given ERC20 token
    * @param _underlying Address of the ERC20 underlying for the PalPool
    * @return address : address of the PalPool
    */
    function getPool(address _underlying) external view returns(address){
        return palPools[_underlying];
    }

    /**
    * @notice Return the PalToken linked to a given ERC20 token
    * @param _underlying Address of the ERC20 underlying for the PalToken
    * @return address : address of the PalToken
    */
    function getToken(address _underlying) external view returns(address){
        return palTokens[_underlying];
    }

    /**
    * @notice Return the PalToken linked to a given PalPool
    * @param _pool Address of the PalToken linked to the PalPool
    * @return address : address of the PalToken
    */
    function getTokenByPool(address _pool) external view returns(address){
        return palTokensByPool[_pool];
    }

    /**
    * @notice Update the Paladin Controller address
    * @param _newAddress Address of the new Controller
    */
    function _setController(address _newAddress) external adminOnly {
        controller = _newAddress;
    }

    /**
    * @notice Add a new Pool to the Registry
    * @dev Admin fucntion : Add a new PalPool & PalToken in the registry
    * @param _underlying Pool underlying ERC20 address
    * @param _pool PalPool address
    * @param _token PalToken address
    */
    function _setPool(address _underlying, address _pool, address _token) external adminOnly {
        palPools[_underlying] = _pool;
        palTokens[_underlying] = _token;
        palTokensByPool[_pool] = _token;
    }

}

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT


/** @title Admin contract  */
/// @author Paladin
contract Admin {

    /** @notice (Admin) Event when the contract admin is updated */
    event NewAdmin(address oldAdmin, address newAdmin);

    /** @dev Admin address for this contract */
    address payable internal admin;
    
    modifier adminOnly() {
        //allows only the admin of this contract to call the function
        require(msg.sender == admin, '1');
        _;
    }

        /**
    * @notice Set a new Admin
    * @dev Changes the address for the admin parameter
    * @param _newAdmin address of the new Controller Admin
    */
    function setNewAdmin(address payable _newAdmin) external adminOnly {
        address _oldAdmin = admin;
        admin = _newAdmin;

        emit NewAdmin(_oldAdmin, _newAdmin);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 25000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}