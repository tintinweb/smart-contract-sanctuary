pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IConsensusUSD.sol";


contract ConsensusUSD is ERC20, IConsensusUSD {

fallback() external payable {
revert();
}

receive() external payable {
revert();
}

string public name;
uint8 public decimals;
string public symbol;
string public version = 'H1.0';

mapping (address => uint256) validStablecoins;
mapping (address => mapping (address => uint256)) lockedAssets;

using SafeMath for uint256;


constructor() public {
decimals = 18;
totalSupply = 0;
name = "Consensus USD";
symbol = "XUSD";

validStablecoins[0x6B175474E89094C44Da98b954EedeAC495271d0F] = 1; // DAI  (MC DAI       )
validStablecoins[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 1; // USDT (ERC20 Tether )
validStablecoins[0x4Fabb145d64652a948d72533023f6E7A623C7C53] = 1; // BUSD (Binance USD  )
validStablecoins[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 1; // USDC (USD Coin     )
validStablecoins[0x0000000000085d4780B73119b644AE5ecd22b376] = 1; // tUSD (TrueUSD      )

}


function isValidAsset(address _asset) external view override returns (bool isValid) {
return validStablecoins[_asset] == 1;
}

function assetLockedOf(address _owner, address _asset) external view override returns (uint256 asset) {
return lockedAssets[_owner][_asset];
}


function mint(uint256 _amount, address _assetUsed) public override returns (bool success) {

assert(validStablecoins[_assetUsed] == 1 );
require(IERC20(_assetUsed).transferFrom(msg.sender, address(this), _amount));

lockedAssets[msg.sender][_assetUsed] = lockedAssets[msg.sender][_assetUsed].add(_amount);

totalSupply          = totalSupply          .add(_amount);
balances[msg.sender] = balances[msg.sender] .add(_amount);

emit Mint(msg.sender, _amount);

return true;
}

function retrieve(uint256 _amount, address _assetRetrieved) public override returns (bool success) {

assert(validStablecoins[_assetRetrieved] == 1 );

assert( balances[msg.sender]                               .sub(_amount) >= 0 );
assert( lockedAssets[msg.sender][_assetRetrieved] .sub(_amount) >= 0 );

balances[msg.sender] = balances[msg.sender] .sub(_amount);
totalSupply          = totalSupply          .sub(_amount);

require(IERC20(_assetRetrieved).transfer(msg.sender, _amount));
lockedAssets[msg.sender][_assetRetrieved] = lockedAssets[msg.sender][_assetRetrieved].sub(_amount);

emit Burn(msg.sender, _amount);

return true;
}

}
