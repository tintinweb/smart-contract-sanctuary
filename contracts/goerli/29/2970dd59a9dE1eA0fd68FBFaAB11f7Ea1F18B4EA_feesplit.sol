pragma solidity ^0.8.7;

interface IWETH {
  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);
}

interface IERC721 {
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

contract feesplit {
  struct payerData {
    uint96 gas;
    address payer;
  }

  address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  address[3] public rccsquad;
  payerData public info;

  constructor(
    address calvin,
    address trippy,
    address fried
  ) {
    rccsquad[0] = calvin;
    rccsquad[1] = trippy;
    rccsquad[2] = fried;
  }

  function execute(
    uint256 position,
    address nft_contract,
    bytes[] memory payload,
    bool multi
  ) external payable {
    uint256 compensate = gasleft();

    require(info.gas == 0, "not again");
    require(msg.sender == rccsquad[position], "fuck off!");

    if (multi) _executeCodes(payable(nft_contract), payload);
    else _executeCode(payable(nft_contract), payload[0], 1);

    info = payerData(uint96((compensate - gasleft() + 21000) * tx.gasprice + msg.value - 1e17), msg.sender); // 1e17 is what caller pays for mint, 21000 is function call gas
  }

  // call below when gas wars over
  function giveNFT(
    address nft,
    uint256 id,
    uint256 position
  ) external {
    require(rccsquad[position] == msg.sender, "no!");
    if (msg.sender != info.payer) {
      require(IWETH(weth).transferFrom(msg.sender, info.payer, info.gas / 2), "PAY"); // transfer first gas to payer, then get your nft
    }

    IERC721(nft).safeTransferFrom(address(this), msg.sender, id);
    rccsquad[position] = address(0);
  }

  function _executeCode(
    address payable target,
    bytes memory payload,
    uint256 div
  ) private {
    (bool success, ) = target.call{ value: msg.value / div }(payload);
    require(success, "fuck");
  }

  function _executeCodes(address payable target, bytes[] memory payload) private {
    _executeCode(target, payload[0], 3);
    _executeCode(target, payload[1], 3);
    _executeCode(target, payload[2], 3);
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1
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