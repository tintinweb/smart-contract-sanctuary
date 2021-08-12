/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: MIT

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

contract BRingRewardsDistribution is Ownable {

  mapping(address => mapping(address => uint256)) public distributionMap;
  mapping(address => address[]) public receipients;
  mapping(address => uint256) public lastIdxs;

  constructor() {
    

    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x9Dda875fb38458aF3cDaE10eeae0AF321d5fB48A)] = 1675274644263770596808;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x9Dda875fb38458aF3cDaE10eeae0AF321d5fB48A));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x766442bBb4e9c326e104484dee2165b3983a5Cb9)] = 221343760081705312359;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x766442bBb4e9c326e104484dee2165b3983a5Cb9));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x7adDe2e71417E1574BdFC7732DEC759082f91A21)] = 52850037184113801913;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x7adDe2e71417E1574BdFC7732DEC759082f91A21));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xB234A630062161F8376507e773e23bC4cBa49676)] = 259669582799010299822;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xB234A630062161F8376507e773e23bC4cBa49676));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xa5570931e213Ee6e761703AFD609cBF9D91336da)] = 519510462483374453768;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xa5570931e213Ee6e761703AFD609cBF9D91336da));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xFd81dC58626a178CD3b724dc71ec17BaDC868B20)] = 634200446209365622962;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xFd81dC58626a178CD3b724dc71ec17BaDC868B20));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x10E6dAD4bB48ae5F8B73D140d61dc2057Df25a5f)] = 418126299656285311812;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x10E6dAD4bB48ae5F8B73D140d61dc2057Df25a5f));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x3168E35D3b9fc77564667c49d18155e75aF8Aa4B)] = 332511215583047487598;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x3168E35D3b9fc77564667c49d18155e75aF8Aa4B));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x64882d0F5513c0Fdf8c6225D01971B10026AE778)] = 58344714135207162541;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x64882d0F5513c0Fdf8c6225D01971B10026AE778));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x81aA6141923Ea42fCAa763d9857418224d9b025a)] = 211387634852002463503;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x81aA6141923Ea42fCAa763d9857418224d9b025a));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x3BD8b9EDB053902FD71578761BA238Acfbdb0c1B)] = 211381377909776091428;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x3BD8b9EDB053902FD71578761BA238Acfbdb0c1B));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x8aBc16e919C61D5863b34F920dfb4Dc4a97bF036)] = 922741181137881653739;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x8aBc16e919C61D5863b34F920dfb4Dc4a97bF036));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x049a49b46255a715441433f9e8E398561cb408D7)] = 357223954435158987053;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x049a49b46255a715441433f9e8E398561cb408D7));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xFfdDfdCAE66BBC1cb9F9F12D5F631c5d68Dff537)] = 291697666935218592243;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xFfdDfdCAE66BBC1cb9F9F12D5F631c5d68Dff537));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x8cEC27A195145143E0B6e75574e0ebCD0C0D4805)] = 158531340725662289514;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x8cEC27A195145143E0B6e75574e0ebCD0C0D4805));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x60D900365BB8cC8d8E817a7EA884b37db8923Ba1)] = 79263324009496244570;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x60D900365BB8cC8d8E817a7EA884b37db8923Ba1));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x8c96Cb362bB43D6e4560e1237484fb06D6Ae0cf7)] = 212115525797670755991;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x8c96Cb362bB43D6e4560e1237484fb06D6Ae0cf7));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x391B3DD314563Bd3642048Efd5a4854C547Ca138)] = 146271208352600751823;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x391B3DD314563Bd3642048Efd5a4854C547Ca138));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x6fFbcA4259dFceC4B72BEd5008704468208e7635)] = 289588646797899400553;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x6fFbcA4259dFceC4B72BEd5008704468208e7635));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xF2Dc8De5D42BE1f1Fd916f4e532E051351d71aa5)] = 421966265815166309494;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xF2Dc8De5D42BE1f1Fd916f4e532E051351d71aa5));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x75F82bC64CD8B7E8D6CE8611ab2600A9cB01179F)] = 211318808487512342253;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x75F82bC64CD8B7E8D6CE8611ab2600A9cB01179F));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xE15ecfC8d69D291A756df25B26BA57D3253EcF4f)] = 105643761888190226727;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xE15ecfC8d69D291A756df25B26BA57D3253EcF4f));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x3aBa77F76f2CfbAC1389878959E24fAA1afCA68F)] = 79230475062807784070;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x3aBa77F76f2CfbAC1389878959E24fAA1afCA68F));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x8dAA44B2C0f83Aa2bD97601641e4001d5bF4AC71)] = 216486690767044507310;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x8dAA44B2C0f83Aa2bD97601641e4001d5bF4AC71));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xfD254cF7c535a32B987A3AF7034ffDDD1a67d7Cb)] = 7748195819329700498201;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xfD254cF7c535a32B987A3AF7034ffDDD1a67d7Cb));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x13255186B4AA67232FB0644647208162CC8d844D)] = 211828749278961907975;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x13255186B4AA67232FB0644647208162CC8d844D));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x9B85516e4b4c59797af970801b3A13D66f910e37)] = 211093558567362833855;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x9B85516e4b4c59797af970801b3A13D66f910e37));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xF6FBA9B30A0e90Eb666CE59e8900D2a47d17Ff99)] = 7221942771879037536564;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xF6FBA9B30A0e90Eb666CE59e8900D2a47d17Ff99));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xA4d3eA01e5205f349aFfa727632d6B8b6FC28Da9)] = 110781414617170483438;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xA4d3eA01e5205f349aFfa727632d6B8b6FC28Da9));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x28a3c2dA2bcc5C0A274627a391A5cb64d946c2E3)] = 1914995181445365460604;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x28a3c2dA2bcc5C0A274627a391A5cb64d946c2E3));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x5382A0739b47F592af1c15559c29Fe0CA44B98B3)] = 189826527766521905959;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x5382A0739b47F592af1c15559c29Fe0CA44B98B3));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x3C97c372B45cC96Fe73814721ebbE6db02C9D88E)] = 522593818379439994714;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x3C97c372B45cC96Fe73814721ebbE6db02C9D88E));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x37425c7CCAAB7D61560f0CaFc77a947a8Eae09E9)] = 240124045369386038828;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x37425c7CCAAB7D61560f0CaFc77a947a8Eae09E9));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x33b8DBFcd046cEf86806a83007a5B2f810Ea4473)] = 686327702514033830993;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x33b8DBFcd046cEf86806a83007a5B2f810Ea4473));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x1dC122dB61D53A8E088d63Af743F4D4c713e8A20)] = 78951259015955798759;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x1dC122dB61D53A8E088d63Af743F4D4c713e8A20));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x20997325098692337A03961317eBf912Bf913b65)] = 207704381528076396534;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x20997325098692337A03961317eBf912Bf913b65));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x5e4B9eE7Bc57D77e13b050e078885651B4D092cc)] = 126273210276163553089;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x5e4B9eE7Bc57D77e13b050e078885651B4D092cc));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xa1e40507FAc3E4222A6aD59BD799a344190a204A)] = 210442836575819853806;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xa1e40507FAc3E4222A6aD59BD799a344190a204A));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xFfd2a8f4275E76288D31DBb756Ce0e6065A3D766)] = 573794888388673598456;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xFfd2a8f4275E76288D31DBb756Ce0e6065A3D766));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x922f2928f4d244611e8beF9e8dAD88A5B6E2B59C)] = 262117628204746210940;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x922f2928f4d244611e8beF9e8dAD88A5B6E2B59C));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xc7d23FE48F3DAE21b5B91568eDFF2a103b1E2E6A)] = 210223843597896717483;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xc7d23FE48F3DAE21b5B91568eDFF2a103b1E2E6A));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x4524331C52A73bdfD1668907f28a4860307201Ae)] = 326452410785681536253;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x4524331C52A73bdfD1668907f28a4860307201Ae));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xDDF33967Ff57A679E3B65f8f70eE393e075Bfa59)] = 312001511078247631303;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xDDF33967Ff57A679E3B65f8f70eE393e075Bfa59));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xd40f0D8f08Eb702Ce5b4Aa039a7B004043433098)] = 87542409018886147009;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xd40f0D8f08Eb702Ce5b4Aa039a7B004043433098));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x121D26685013baf726e309F5762ecEe520Fcc702)] = 209936024255483459910;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x121D26685013baf726e309F5762ecEe520Fcc702));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x02fEC1e5e224Da14Dfe29237042D56a96523949E)] = 107302295728589939471;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x02fEC1e5e224Da14Dfe29237042D56a96523949E));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xcbC4a69a93C52693A0812780f216EfAc684353b0)] = 518199298581879020275;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xcbC4a69a93C52693A0812780f216EfAc684353b0));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x88875CdA27Fe441Ed0773bFE6d45904373089958)] = 95527226041274360568;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x88875CdA27Fe441Ed0773bFE6d45904373089958));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x5F85a3aA9619bc37B7E7587C5870C270d0Ab8A72)] = 52452011111770033835;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x5F85a3aA9619bc37B7E7587C5870C270d0Ab8A72));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xf6865bAaAE3f57D8a8046ee635a0DA9fC8f0243b)] = 64309054212531052030;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xf6865bAaAE3f57D8a8046ee635a0DA9fC8f0243b));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x84Bc82B1e14Ce515260708D77BfFf7CD1261c927)] = 284180984209066878065;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x84Bc82B1e14Ce515260708D77BfFf7CD1261c927));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x7F781792935A505487251Be1b371094898274802)] = 1214555701170785823705;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x7F781792935A505487251Be1b371094898274802));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x8eA0B045bC4E5aF4d63A5cDeBDc8f69B06AB988b)] = 888702692783342058646;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x8eA0B045bC4E5aF4d63A5cDeBDc8f69B06AB988b));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x7604100fc7d73FB2179dafd86A93a3215502ebae)] = 311590985474359627005;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x7604100fc7d73FB2179dafd86A93a3215502ebae));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x0a06a207f2e2F10eA6eca653A66D086553b94839)] = 20645090743539260103;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x0a06a207f2e2F10eA6eca653A66D086553b94839));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x4F9476A750Aa3dEbcd3e72340A53c590AeA288a4)] = 162628651998407775636;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x4F9476A750Aa3dEbcd3e72340A53c590AeA288a4));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x8084d3FB905F31663153898FE034Dce72B7D2297)] = 114942553821621132215;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x8084d3FB905F31663153898FE034Dce72B7D2297));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x108B3731b012C4F2Cd11E777EDb6dB4f92216aBC)] = 254067012447143724784;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x108B3731b012C4F2Cd11E777EDb6dB4f92216aBC));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xB3881CFc78f927F620638BF853ad00aae806eb0e)] = 718224710914842944475;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xB3881CFc78f927F620638BF853ad00aae806eb0e));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xAe8C5C72b63f7b060058E222a159Fcfd9c5Cf5F7)] = 703667052135737776552;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xAe8C5C72b63f7b060058E222a159Fcfd9c5Cf5F7));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x54DCAc795bf85f78f9c23B5d72b849E4a78e309d)] = 75039009509871263503;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x54DCAc795bf85f78f9c23B5d72b849E4a78e309d));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xe0dF66924bE8F6E24879f1F6771470Bdc0648086)] = 56076216191617476169;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xe0dF66924bE8F6E24879f1F6771470Bdc0648086));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x2C12708ef3E449068E9B3FDB2016122181C84aEA)] = 18807645170987814964;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x2C12708ef3E449068E9B3FDB2016122181C84aEA));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xb10BD34199663ebfBF20D740959D773e34030B59)] = 1661500494071147841168;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xb10BD34199663ebfBF20D740959D773e34030B59));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x3341c7C754C6c2Ebf524D411849D47F87cCD8A7B)] = 121300189650091013504;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x3341c7C754C6c2Ebf524D411849D47F87cCD8A7B));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x92DF2a5104FcE10d77496710488382Eb53def917)] = 44977683984454387200;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x92DF2a5104FcE10d77496710488382Eb53def917));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xa66911F56c40050B977cf704e755d0bEdba2CBf7)] = 326290260910762185631;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xa66911F56c40050B977cf704e755d0bEdba2CBf7));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x657dd0c36CAb330D5dF1Bd45d327d0e6c3F7e2D5)] = 21363089973231215168;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x657dd0c36CAb330D5dF1Bd45d327d0e6c3F7e2D5));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xba9634ee7E978f0aB649976a5a76e268DAc50Af6)] = 6666319150873579069;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xba9634ee7E978f0aB649976a5a76e268DAc50Af6));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xD220E7371529c5B4137c8eED97288a84fF09bBF8)] = 330509437181161217722;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xD220E7371529c5B4137c8eED97288a84fF09bBF8));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xEf92D1638b63dd82BD744fFfb96f9d46B0eEc50E)] = 40970410762757381917;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xEf92D1638b63dd82BD744fFfb96f9d46B0eEc50E));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xd81AF520255A973825B7D62dFC998c1316cFFc3B)] = 13457823230904434552;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xd81AF520255A973825B7D62dFC998c1316cFFc3B));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xB965d68052B849B29fE25497C51659BF9678bC9B)] = 102546499465826300934;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xB965d68052B849B29fE25497C51659BF9678bC9B));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x1Ccfd38a7cA6E3946aBeD21bdfb2Acd9dd77b33a)] = 44094906487926415650;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x1Ccfd38a7cA6E3946aBeD21bdfb2Acd9dd77b33a));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x43D8D77b3c63E759d2232FdEb0CB3826541677aa)] = 5323382306211501990;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x43D8D77b3c63E759d2232FdEb0CB3826541677aa));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xc6919543A40D33A39Ddf109372f2128B34b46727)] = 8517411689938402474;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xc6919543A40D33A39Ddf109372f2128B34b46727));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x81178B143737677629D61D47199D76a32B537D96)] = 107310071374187998571;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x81178B143737677629D61D47199D76a32B537D96));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0xf7C0D2374DDF2AE9BEAfEAAfEb89E6A2725300c5)] = 5281465910099600868;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0xf7C0D2374DDF2AE9BEAfEAAfEb89E6A2725300c5));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x6BF2AF99E7c12B2A4C3B645d3f47306457EF6506)] = 5268568557449785139;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x6BF2AF99E7c12B2A4C3B645d3f47306457EF6506));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x81dcAB1513d88478a3536348d6d7560f2d8762a4)] = 12784500814129984291;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x81dcAB1513d88478a3536348d6d7560f2d8762a4));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x553f20EB9422b33256F464577D16B81dB477A1D9)] = 49719294465040192676;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x553f20EB9422b33256F464577D16B81dB477A1D9));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x6FfE90a6B0E6Ed5398e5ae58367e20Fd2E26CBF8)] = 66469134716428513343;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x6FfE90a6B0E6Ed5398e5ae58367e20Fd2E26CBF8));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x1aDcF07389b1F6605C44a7683c50A5243829A92C)] = 284918641725244981444;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x1aDcF07389b1F6605C44a7683c50A5243829A92C));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x0a8bF5bEC994CED54b120fcd9dbD3A2Cd9dA94Cc)] = 17360178446497386062;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x0a8bF5bEC994CED54b120fcd9dbD3A2Cd9dA94Cc));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x42D73FD3f142b5cC650DF8F03325ae5c871818a6)] = 44955334830014457736;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x42D73FD3f142b5cC650DF8F03325ae5c871818a6));
    distributionMap[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)][address(0x52f300747aFE206Ad2fC35863849c4A0594635B6)] = 3644630641929842873;
    receipients[address(0x3Ecb96039340630c8B82E5A7732bc88b2aeadE82)].push(address(0x52f300747aFE206Ad2fC35863849c4A0594635B6));

  }

  

  function distribute(address _tokenAddress, uint8 _receipientsNumber) external onlyOwner {
    uint8 j = 0;
    for (uint256 i = lastIdxs[_tokenAddress]; j < _receipientsNumber && i < receipients[_tokenAddress].length; i++) {
      lastIdxs[_tokenAddress] = i + 1;
      IERC20(_tokenAddress).transfer(
        receipients[_tokenAddress][i],
        distributionMap[_tokenAddress][receipients[_tokenAddress][i]]
      );

      j++;
    }
  }

  function calculate(address _tokenAddress) external view returns (uint256) {
    uint256 totalAmount;

    for (uint256 i = 0; i < receipients[_tokenAddress].length; i++) {
      totalAmount+= distributionMap[_tokenAddress][receipients[_tokenAddress][i]];
    }

    return totalAmount;
  }

  function retrieveTokens(address _tokenAddress, uint256 _amount) external onlyOwner {
    require(_amount > 0, "Invalid amount");

    IERC20(_tokenAddress).transfer(owner(), _amount);
  }

}