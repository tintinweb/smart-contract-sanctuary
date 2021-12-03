//SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
contract HashmonNFT is ERC721, ERC721Burnable, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  struct Params {
	uint256 HashPowerNum;   //T,Decimals:1,1 means 1T
	uint256 qulity;//1-normal,...6,legendary
	uint256 EnergyConsumptionRatio;//Decimals:2,0.01*EnergyConsumptionRatio J/TH,2955 means 29.55J/TH
	uint256 initBlock;
    }
  mapping(uint256 => Params) public paramsOf;

  uint256 public powerFeebyUSDTPerKWHour = 8e16;  //Decimals:18,8e16 means  0.08U per KWHour
  uint256 public constant MaxTokenId = 2222220;

  constructor() public ERC721("HashmonNFT", "Hashmon") {}
  event Minted(address indexed owner, uint256 indexed id, uint256 HashPowerNum, uint256 quality);

  function mint(address recipient, string memory uri,uint256 _HashPowerNum,uint256 _quality,uint256 _EnergyConsumptionRatio)
    public onlyOwner
    returns (uint256)
  {
    require( _tokenIds.current()<MaxTokenId, 'Exceed');
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _mint(recipient, newItemId);
    _setTokenURI(newItemId, uri);
    paramsOf[newItemId] = Params(_HashPowerNum, _quality, _EnergyConsumptionRatio,block.number);
    emit Minted(recipient, newItemId,_HashPowerNum,_quality);
    return newItemId;
  }
}