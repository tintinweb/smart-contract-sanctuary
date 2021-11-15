//SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

interface IFxStateSender {
  function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

contract PolygonMessageSender {

  address constant FX_ROOT_ADDRESS = 0xfe5e5D361b2ad62c541bAb87C45a0B9B018389a2;
  address constant POLYGON_BRIDGE_EXECUTOR = 0x60966EA42764c7c538Af9763Bc11860eB2556E6B;
  address constant MARKET_UPDATE = 0x5B494b94FaF0BB63254Dba26F17483BCF57F6d6A;
  string constant functionSignature = 'executeUpdate()';

  event UpdateSuccess(address sender);

  function sendMessage() external {
    IFxStateSender fxRoot = IFxStateSender(FX_ROOT_ADDRESS);

    address[] memory targets = new address[](1);
    uint256[] memory values = new uint256[](1);
    string[] memory signatures = new string[](1);
    bytes[] memory calldatas = new bytes[](1);
    bool[] memory withDelegates = new bool[](1);

    targets[0] = MARKET_UPDATE;
    values[0] = uint256(0);
    signatures[0] = functionSignature;
    calldatas[0] = new bytes(0);
    withDelegates[0] = true;

    bytes memory encodedData = abi.encode(
        targets,
        values,
        signatures,
        calldatas,
        withDelegates
    );
    
    fxRoot.sendMessageToChild(POLYGON_BRIDGE_EXECUTOR, encodedData);
  }
}

