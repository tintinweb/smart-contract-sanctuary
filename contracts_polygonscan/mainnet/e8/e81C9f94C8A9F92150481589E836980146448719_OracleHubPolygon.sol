/**
 *Submitted for verification at polygonscan.com on 2021-11-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//import the ERC20 interface

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract OracleHubPolygon {



    address public masterAddress = msg.sender;
    mapping(address => address) oracle;
    
    address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; 
    address constant  USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; 
    address constant dQuick = 0xf28164A485B0B2C90639E47b0f377b4a438a16B1;
    address constant  Quick = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
    address constant  Eth = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address constant  USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant  WBTC = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address constant Aave = 0xD6DF932A45C0f255f85145f286eA0b292B21C90B;
    address constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address constant LINK = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;
    address constant  UNI = 0xb33EaAd8d922B1083446DC23f610c2567fB5180f;
    
  
    
    

 modifier onlyMaster() {
        require(
        msg.sender == masterAddress,
            "Not Master"
        );
        _;
    }

 function renounceOwnership()
        external
        onlyMaster
    {
        masterAddress = address(0x0);
    }
    
    function forwardOwnership(
        address payable _newMaster
    )
        external
        onlyMaster
    {
        masterAddress = _newMaster;
    }
    
    
    
    function addMemberOracle(address token, address oracleAddress) external onlyMaster returns(bool){
        
        oracle[token] = oracleAddress;
        
        return true;
        
    }
    
    function showOracleAddress(address token) external view returns(address){
        
        
        
        return oracle[token];
    }
    
      function initializeAndDefaultSettings() external onlyMaster returns(bool){
    
    oracle[WMATIC] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
    oracle[USDT] = 0x0A6513e40db6EB1b165753AD52E80663aeA50545;
    oracle[Quick] =0xa058689f4bCa95208bba3F265674AE95dED75B6D;
    oracle[Eth] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
    oracle[USDC] = 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7;
    oracle[WBTC] = 0xDE31F8bFBD8c84b5360CFACCa3539B938dd78ae6;
    oracle[Aave] = 0x72484B12719E23115761D5DA1646945632979bB6;
    oracle[DAI] = 0x4746DeC9e833A82EC7C2C1356372CcF2cfcD2F3D;
    oracle[LINK] = 0xd9FFdb71EbE7496cC440152d43986Aae0AB76665;
    oracle[UNI] = 0xdf0Fb4e4F928d2dCB76f438575fDD8682386e13C;
    
    return true;
    }
    
}