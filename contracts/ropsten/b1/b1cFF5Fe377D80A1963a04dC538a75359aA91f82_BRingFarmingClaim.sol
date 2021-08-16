/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

pragma solidity >=0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BRingFarmingClaim is Ownable {

  
  mapping(address => mapping(address => uint256)) public distributionMap;
  mapping(address => bool) public receivedClaims;

  address[] public tokensAddresses;

  constructor() {
    tokensAddresses.push(address(0x73E5CFe15F5F0A3b35893BCa1174b4952c9F68a8)); 
    tokensAddresses.push(address(0x72e7C274BfB364304f92dD17B64a16C57915a537)); 
    tokensAddresses.push(address(0x5f670d536F0EE971208d34E4c4385BC5D80a034E)); 
    tokensAddresses.push(address(0xdce97c92E5D18611D6e27C8f7377a136701a765d)); 
    tokensAddresses.push(address(0xeFd8fffa7817fe8C1D62c73469345C29d2a1fC7F)); 

    //0x358565D631d946b4E069A866254274901eEaE794
    distributionMap[address(0x358565D631d946b4E069A866254274901eEaE794)][address(0x73E5CFe15F5F0A3b35893BCa1174b4952c9F68a8)] = 1000000000000000000000;
    distributionMap[address(0x358565D631d946b4E069A866254274901eEaE794)][address(0x72e7C274BfB364304f92dD17B64a16C57915a537)] = 900000000000000000000;
    distributionMap[address(0x358565D631d946b4E069A866254274901eEaE794)][address(0x5f670d536F0EE971208d34E4c4385BC5D80a034E)] = 800000000000000000000;
    distributionMap[address(0x358565D631d946b4E069A866254274901eEaE794)][address(0xdce97c92E5D18611D6e27C8f7377a136701a765d)] = 700000000000000000000;
    distributionMap[address(0x358565D631d946b4E069A866254274901eEaE794)][address(0xeFd8fffa7817fe8C1D62c73469345C29d2a1fC7F)] = 600000000000000000000;
    //0xD666cAD67038c8d021d7810b075D7309e78F5845
    distributionMap[address(0xD666cAD67038c8d021d7810b075D7309e78F5845)][address(0x73E5CFe15F5F0A3b35893BCa1174b4952c9F68a8)] = 1000000000000000000000;
    distributionMap[address(0xD666cAD67038c8d021d7810b075D7309e78F5845)][address(0x72e7C274BfB364304f92dD17B64a16C57915a537)] = 900000000000000000000;
    distributionMap[address(0xD666cAD67038c8d021d7810b075D7309e78F5845)][address(0x5f670d536F0EE971208d34E4c4385BC5D80a034E)] = 800000000000000000000;
    distributionMap[address(0xD666cAD67038c8d021d7810b075D7309e78F5845)][address(0xdce97c92E5D18611D6e27C8f7377a136701a765d)] = 700000000000000000000;
    distributionMap[address(0xD666cAD67038c8d021d7810b075D7309e78F5845)][address(0xeFd8fffa7817fe8C1D62c73469345C29d2a1fC7F)] = 600000000000000000000;
    //0xA204D5e4dC8B802C7ae835b9b2592afFBF87c2e8
    distributionMap[address(0xA204D5e4dC8B802C7ae835b9b2592afFBF87c2e8)][address(0x73E5CFe15F5F0A3b35893BCa1174b4952c9F68a8)] = 1000000000000000000000;
    distributionMap[address(0xA204D5e4dC8B802C7ae835b9b2592afFBF87c2e8)][address(0x72e7C274BfB364304f92dD17B64a16C57915a537)] = 900000000000000000000;
    distributionMap[address(0xA204D5e4dC8B802C7ae835b9b2592afFBF87c2e8)][address(0x5f670d536F0EE971208d34E4c4385BC5D80a034E)] = 800000000000000000000;
    distributionMap[address(0xA204D5e4dC8B802C7ae835b9b2592afFBF87c2e8)][address(0xdce97c92E5D18611D6e27C8f7377a136701a765d)] = 700000000000000000000;
    distributionMap[address(0xA204D5e4dC8B802C7ae835b9b2592afFBF87c2e8)][address(0xeFd8fffa7817fe8C1D62c73469345C29d2a1fC7F)] = 600000000000000000000;
    //0xf31AA959D6bd5777Be0f1c8436469F220463a810
    distributionMap[address(0xf31AA959D6bd5777Be0f1c8436469F220463a810)][address(0x73E5CFe15F5F0A3b35893BCa1174b4952c9F68a8)] = 1000000000000000000000;
    distributionMap[address(0xf31AA959D6bd5777Be0f1c8436469F220463a810)][address(0x72e7C274BfB364304f92dD17B64a16C57915a537)] = 900000000000000000000;
    distributionMap[address(0xf31AA959D6bd5777Be0f1c8436469F220463a810)][address(0x5f670d536F0EE971208d34E4c4385BC5D80a034E)] = 800000000000000000000;
    distributionMap[address(0xf31AA959D6bd5777Be0f1c8436469F220463a810)][address(0xdce97c92E5D18611D6e27C8f7377a136701a765d)] = 700000000000000000000;
    distributionMap[address(0xf31AA959D6bd5777Be0f1c8436469F220463a810)][address(0xeFd8fffa7817fe8C1D62c73469345C29d2a1fC7F)] = 600000000000000000000;
    //0xB203814E6633de71F0c3F51696459F32547cC866
    distributionMap[address(0xB203814E6633de71F0c3F51696459F32547cC866)][address(0x73E5CFe15F5F0A3b35893BCa1174b4952c9F68a8)] = 1000000000000000000000;
    distributionMap[address(0xB203814E6633de71F0c3F51696459F32547cC866)][address(0x72e7C274BfB364304f92dD17B64a16C57915a537)] = 900000000000000000000;
    distributionMap[address(0xB203814E6633de71F0c3F51696459F32547cC866)][address(0x5f670d536F0EE971208d34E4c4385BC5D80a034E)] = 800000000000000000000;
    distributionMap[address(0xB203814E6633de71F0c3F51696459F32547cC866)][address(0xdce97c92E5D18611D6e27C8f7377a136701a765d)] = 700000000000000000000;
    distributionMap[address(0xB203814E6633de71F0c3F51696459F32547cC866)][address(0xeFd8fffa7817fe8C1D62c73469345C29d2a1fC7F)] = 600000000000000000000;
    //0x2feB78cC27E271044427a79B47d5D1e1a3720AEb
    distributionMap[address(0x2feB78cC27E271044427a79B47d5D1e1a3720AEb)][address(0x73E5CFe15F5F0A3b35893BCa1174b4952c9F68a8)] = 1000000000000000000000;
    distributionMap[address(0x2feB78cC27E271044427a79B47d5D1e1a3720AEb)][address(0x72e7C274BfB364304f92dD17B64a16C57915a537)] = 900000000000000000000;
    distributionMap[address(0x2feB78cC27E271044427a79B47d5D1e1a3720AEb)][address(0x5f670d536F0EE971208d34E4c4385BC5D80a034E)] = 800000000000000000000;
    distributionMap[address(0x2feB78cC27E271044427a79B47d5D1e1a3720AEb)][address(0xdce97c92E5D18611D6e27C8f7377a136701a765d)] = 700000000000000000000;
    distributionMap[address(0x2feB78cC27E271044427a79B47d5D1e1a3720AEb)][address(0xeFd8fffa7817fe8C1D62c73469345C29d2a1fC7F)] = 600000000000000000000;
    //0xceFF424BbC7ef4543d181472D71FC05fA7e7D856
    distributionMap[address(0xceFF424BbC7ef4543d181472D71FC05fA7e7D856)][address(0x73E5CFe15F5F0A3b35893BCa1174b4952c9F68a8)] = 1000000000000000000000;
    distributionMap[address(0xceFF424BbC7ef4543d181472D71FC05fA7e7D856)][address(0x72e7C274BfB364304f92dD17B64a16C57915a537)] = 900000000000000000000;
    distributionMap[address(0xceFF424BbC7ef4543d181472D71FC05fA7e7D856)][address(0x5f670d536F0EE971208d34E4c4385BC5D80a034E)] = 800000000000000000000;
    distributionMap[address(0xceFF424BbC7ef4543d181472D71FC05fA7e7D856)][address(0xdce97c92E5D18611D6e27C8f7377a136701a765d)] = 700000000000000000000;
    distributionMap[address(0xceFF424BbC7ef4543d181472D71FC05fA7e7D856)][address(0xeFd8fffa7817fe8C1D62c73469345C29d2a1fC7F)] = 600000000000000000000;
    //0xB203814E6633de71F0c3F51696459F32547cC866
    distributionMap[address(0xB203814E6633de71F0c3F51696459F32547cC866)][address(0x73E5CFe15F5F0A3b35893BCa1174b4952c9F68a8)] = 1000000000000000000000;
    distributionMap[address(0xB203814E6633de71F0c3F51696459F32547cC866)][address(0x72e7C274BfB364304f92dD17B64a16C57915a537)] = 900000000000000000000;
    distributionMap[address(0xB203814E6633de71F0c3F51696459F32547cC866)][address(0x5f670d536F0EE971208d34E4c4385BC5D80a034E)] = 800000000000000000000;
    distributionMap[address(0xB203814E6633de71F0c3F51696459F32547cC866)][address(0xdce97c92E5D18611D6e27C8f7377a136701a765d)] = 700000000000000000000;
    distributionMap[address(0xB203814E6633de71F0c3F51696459F32547cC866)][address(0xeFd8fffa7817fe8C1D62c73469345C29d2a1fC7F)] = 600000000000000000000;
    //0x0B2498402f40450E41793DB748618c65EA86C434
    distributionMap[address(0x0B2498402f40450E41793DB748618c65EA86C434)][address(0x73E5CFe15F5F0A3b35893BCa1174b4952c9F68a8)] = 1000000000000000000000;
    distributionMap[address(0x0B2498402f40450E41793DB748618c65EA86C434)][address(0x72e7C274BfB364304f92dD17B64a16C57915a537)] = 900000000000000000000;
    distributionMap[address(0x0B2498402f40450E41793DB748618c65EA86C434)][address(0x5f670d536F0EE971208d34E4c4385BC5D80a034E)] = 800000000000000000000;
    distributionMap[address(0x0B2498402f40450E41793DB748618c65EA86C434)][address(0xdce97c92E5D18611D6e27C8f7377a136701a765d)] = 700000000000000000000;
    distributionMap[address(0x0B2498402f40450E41793DB748618c65EA86C434)][address(0xeFd8fffa7817fe8C1D62c73469345C29d2a1fC7F)] = 600000000000000000000;
    //0xD33cd55E5F73F62dD1Adc1f8AECfA8626914b3a5
    distributionMap[address(0xD33cd55E5F73F62dD1Adc1f8AECfA8626914b3a5)][address(0x73E5CFe15F5F0A3b35893BCa1174b4952c9F68a8)] = 1000000000000000000000;
    distributionMap[address(0xD33cd55E5F73F62dD1Adc1f8AECfA8626914b3a5)][address(0x72e7C274BfB364304f92dD17B64a16C57915a537)] = 900000000000000000000;
    distributionMap[address(0xD33cd55E5F73F62dD1Adc1f8AECfA8626914b3a5)][address(0x5f670d536F0EE971208d34E4c4385BC5D80a034E)] = 800000000000000000000;
    distributionMap[address(0xD33cd55E5F73F62dD1Adc1f8AECfA8626914b3a5)][address(0xdce97c92E5D18611D6e27C8f7377a136701a765d)] = 700000000000000000000;
    distributionMap[address(0xD33cd55E5F73F62dD1Adc1f8AECfA8626914b3a5)][address(0xeFd8fffa7817fe8C1D62c73469345C29d2a1fC7F)] = 600000000000000000000;
    //0x13671d01987D35706021e1869bcdcc75F56D51Fa
    distributionMap[address(0x13671d01987D35706021e1869bcdcc75F56D51Fa)][address(0x73E5CFe15F5F0A3b35893BCa1174b4952c9F68a8)] = 1000000000000000000000;
    distributionMap[address(0x13671d01987D35706021e1869bcdcc75F56D51Fa)][address(0x72e7C274BfB364304f92dD17B64a16C57915a537)] = 900000000000000000000;
    distributionMap[address(0x13671d01987D35706021e1869bcdcc75F56D51Fa)][address(0x5f670d536F0EE971208d34E4c4385BC5D80a034E)] = 800000000000000000000;
    distributionMap[address(0x13671d01987D35706021e1869bcdcc75F56D51Fa)][address(0xdce97c92E5D18611D6e27C8f7377a136701a765d)] = 700000000000000000000;
    distributionMap[address(0x13671d01987D35706021e1869bcdcc75F56D51Fa)][address(0xeFd8fffa7817fe8C1D62c73469345C29d2a1fC7F)] = 600000000000000000000;
  }

  function claim() external {
    _claim(msg.sender);
  }

  function claimForAddress(address _userAddress) external  {
    _claim(_userAddress);
  }

  function _claim(address _userAddress) private {
    require(!receivedClaims[_userAddress], "You have received your tokens");

    receivedClaims[_userAddress] = true;
    for (uint8 i = 0; i < tokensAddresses.length; i++) {
      if (distributionMap[_userAddress][tokensAddresses[i]] == 0) {
        continue;
      }

      require(
        IERC20(tokensAddresses[i]).transfer(_userAddress, distributionMap[_userAddress][tokensAddresses[i]]),
        "Token transfer error"
      );
    }
  }

  function retrieveTokens(address _tokenAddress, uint256 _amount) external onlyOwner {
    require(_amount > 0, "Invalid amount");

    IERC20(_tokenAddress).transfer(owner(), _amount);
  }

}