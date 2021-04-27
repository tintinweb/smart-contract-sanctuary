// SPDX-License-Identifier: MIT
// from file output/basdai.json
pragma solidity ^0.6.7;

interface ERC20 {
    function transfer(address _to, uint256 _value) external returns (bool success);
}

contract pBasisBasDaiReimbursement {
  mapping (address => uint256) public amounts;
  mapping (address => bool) public reimbursed;

  address public constant token = 0x3E78F2E7daDe07ea685F8612F00477FD97162F1e;
  address public constant gov = 0x9d074E37d408542FD38be78848e8814AFB38db17;
  
  constructor() public {
    amounts[0xE3E39161d35E9A81edEc667a5387bfAE85752854] = 183513249956549710865;
    amounts[0xb01d8124071C6C0cA2d8a135f2e706ae81CB43AC] = 36711799581219316917;
    amounts[0xdebccc195e08Ab253ea31917DefFBF5121b1cE3A] = 236002603253270962195;
    amounts[0x061De24DC59A974b14F8c8ab400A88Fa62eB9083] = 2045383575359890267330;
    amounts[0x85C447D3fC7d42B1167C7fA6Ee50FDd961512B4E] = 3413634384528390494348;
    amounts[0xabE8b36B5cd7Bf06921eE9afdeA5453A10a8EA1C] = 38135149402302765008;
    amounts[0x76d2DDCe6b781e66c4B184C82Fbf4F94346Cfb0D] = 353434229029673719778;
    amounts[0x1200Eb4fA3dF9903fC6EfF1d7A4a5D17502329b2] = 234154114153735465644;
    amounts[0x98Bf452242DF2D300CDC5aBAc9aBBB40A4c61590] = 2953730987080946840547;
    amounts[0x8cCf4f26c11aad085E356a6F6d46a09EC18B1e0c] = 113022277917639803234;
    amounts[0x87eD8047d60bc2617f2B0cC0c715fCfCD5683618] = 18569223455537041723;
    amounts[0xE31587B06D0353d39cd1f711f4F8828685C20810] = 34761599526235727209;
    amounts[0xF3676Dc97400b23F8b4486D1E360AfCca749FC60] = 1660945500372677291086;
    amounts[0x932654BC075A69AD65CFc76BA01C4ac3621D1598] = 200069949004704536442;
    amounts[0xe8bF424E047372d249d0826c5567655ba3B72f18] = 175406145394121246940;
    amounts[0x8d9d4A1e9726A5478f66B1134c8C61F6D258FA20] = 126078507147366906451;
    amounts[0xFEEDC450742AC0D9bB38341D9939449e3270f76F] = 1;
  }
  
  function claim() public {
    require(!reimbursed[msg.sender], "already reimbursed");
    require(amounts[msg.sender] > 0, "not claimable");
    require(ERC20(token).transfer(msg.sender, amounts[msg.sender]));
    reimbursed[msg.sender] = true;
  }

  function saveERC20(address _erc20, uint256 _amount) public {
    require(msg.sender == gov, "!gov");
    require(ERC20(_erc20).transfer(gov, _amount));
  }  
}

{
  "optimizer": {
    "enabled": true,
    "runs": 9999
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