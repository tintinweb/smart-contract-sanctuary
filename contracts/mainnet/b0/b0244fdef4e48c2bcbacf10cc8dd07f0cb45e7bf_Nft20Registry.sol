// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Nft20Registry is Ownable {
    mapping(address => address) public nftToErc20;
    mapping(address => bool) public authorized;

    constructor() public {
        // add deployer to authorized
        authorized[msg.sender] = true;
        // add existing nftToErc20
        nftToErc20[
            0x274E21d314A915d1504060d4351DdE05d4dC031e
        ] = 0x7a911C71144f4d5a00E4216b1c5b12D9571E9336; // AAH
        nftToErc20[
            0xC7e5e9434f4a71e6dB978bD65B4D61D3593e5f27
        ] = 0xC58641aE25D1E368393cad5CCe2CcA3C80D8fFF6; // Alpaca City
        nftToErc20[
            0x6Fa769EED284a94A73C15299e1D3719B29Ae2F52
        ] = 0xB32ca105F6CCe99074C58B349d095243B6060303; // BFH Unit
        nftToErc20[
            0xb80fBF6cdb49c33dC6aE4cA11aF8Ac47b0b4C0f3
        ] = 0x57C31c042Cb2F6a50F3dA70ADe4fEE20C86B7493; // Block Art
        nftToErc20[
            0x2f2d5aA0EfDB9Ca3C9bB789693d06BEBEa88792F
        ] = 0x5e8DA1DAE500Ff338a2fa66b66c9611288d3f4a7; // Block Cities
        nftToErc20[
            0xC805658931f959abc01133aa13fF173769133512
        ] = 0xaDBEBbd65a041E3AEb474FE9fe6939577eB2544F; // CHONKER20
        nftToErc20[
            0x155CBbcA1Ab35Eab09b66270046317803919E555
        ] = 0xf395F74CA8f7AD4a1f98bBc92cf9a80be1C7B098; // CryptoTendies
        nftToErc20[
            0xa58b5224e2FD94020cb2837231B2B0E4247301A6
        ] = 0x27109aC6B0Cc8DA16B30a7BEA826091797CdF36C; // Crypto Vexels Wearables
        nftToErc20[
            0xF87E31492Faf9A91B02Ee0dEAAd50d51d56D5d4d
        ] = 0x1E0CD9506d465937E9d6754e76Cd389A8bD90FBf; // DECENTRALAND
        nftToErc20[
            0x7CdC0421469398e0F3aA8890693d86c840Ac8931
        ] = 0x22C4AD011Cce6a398B15503e0aB64286568933Ed; // dokidoki20
        nftToErc20[
            0x44d6E8933F8271abcF253C72f9eD7e0e4C0323B3
        ] = 0xB308A5E7cD9534916dB44ee5EC24776654916260; // Don't Rug Me
        nftToErc20[
            0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85
        ] = 0x983021062BC9aA395794C015f9E35AAbBd17Cbd9; // ENS
        nftToErc20[
            0x33b83B6D3179dCb4094c685C2418cab06372eD89
        ] = 0x21993Ed38dCbB8e1612F34676a3D249B5dE538a0; // ETH-MEN
        nftToErc20[
            0x8754F54074400CE745a7CEddC928FB1b7E985eD6
        ] = 0x65f304BFb9DEE92fa77363e7390658063cea6260; // EULER BEATS
        nftToErc20[
            0xc36cF0cFcb5d905B8B513860dB0CFE63F6Cf9F5c
        ] = 0x2E9653caE7f431411727Cdf5581C7fB5fc23bA57; // Gala Games
        nftToErc20[
            0x443B862d3815b1898e85085cAfcA57fC4335a1BE
        ] = 0x5b78eFDcc5ff2ECC141323491BA194293b955E81; // Golfer
        nftToErc20[
            0xC2C747E0F7004F9E8817Db2ca4997657a7746928
        ] = 0xc2BdE1A2fA26890c8E6AcB10C91CC6D9c11F4a73; // Hashmasks
        nftToErc20[
            0xe4605d46Fd0B3f8329d936a8b258D69276cBa264
        ] = 0x60ACD58d00b2BcC9a8924fdaa54A2F7C0793B3b2; // MEME LTD
        nftToErc20[
            0xF9b3B38A458c2512b6680e1F3bc7A022e97D7DAb
        ] = 0x746b9ddF6DdaF05B57F25434d22020F320Cf5842; // MoonBase
        nftToErc20[
            0x73e7dB3cDA787a60a75496Ee07078FB11C3A4c88
        ] = 0x28fa4dEB8354f3c4f8D8f7DC095C7ddF5c4ba607; // NFT20 WRAPLP
        nftToErc20[
            0x89eE76cC25Fcbf1714ed575FAa6A10202B71c26A
        ] = 0x303Af77Cf2774AABff12462C110A0CCf971D7DbE; // NodeRunners
        nftToErc20[
            0xCB6768a968440187157Cfe13b67Cac82ef6cc5a4
        ] = 0xFF22233156b0A4Ae0172825E6891887e8F9d2585; // Pepemon
        nftToErc20[
            0xba8cDaa1C4C294aD634ab3c6Ee0FA82D0A019727
        ] = 0x4df386E4314644ebC7fB67359b83d17977b41c6D; // PolkaPets
        nftToErc20[
            0xDb68Df0e86Bc7C6176E6a2255a5365f51113BCe8
        ] = 0xB3CDC594D8C8e8152d99F162cF8f9eDFdc0A80A2; // ROPE
        nftToErc20[
            0x5351105753Bdbc3Baa908A0c04F1468535749c3D
        ] = 0x7c63164d2E50618c5497ef1e1FBD686e06b7cc12; // Rude Boy
        nftToErc20[
            0xa342f5D851E866E18ff98F351f2c6637f4478dB5
        ] = 0x26080d657A8c52119d0973d0C7FfDB25E7B9b219; // Sandbox's assets
        nftToErc20[
            0x1ca3262009b21F944e6b92a2a88D039D06F1acFa
        ] = 0x8cd81fB9282eC1Cb6d33542eDC2B562644C589cC; // Sergs
        nftToErc20[
            0x629A673A8242c2AC4B7B8C5D8735fbeac21A6205
        ] = 0x793424220968D59FC1A319D434550982708CF6B6; // SORARE
        nftToErc20[
            0xf4680c917A873E2dd6eAd72f9f433e74EB9c623C
        ] = 0x6E9AD2F0Bd0657C6a168375D21f865e33E8f0112; // Twerky Pepe
        nftToErc20[
            0xD1E5b0FF1287aA9f9A268759062E4Ab08b9Dacbe
        ] = 0xb9033e85994453c3E35Bce6FDd1D9fe601492C2a; // Unstoppable Domains
        nftToErc20[
            0xFf488FD296c38a24CCcC60B43DD7254810dAb64e
        ] = 0x96d697A661207A829d2a2C208836A41d76bdae75; // Zed Run
        nftToErc20[
            0x31385d3520bCED94f77AaE104b406994D8F2168C
        ] = 0xcCcBF11AC3030ee8CD7a04CFE15a3718df6dD030; // Bastard punks
        nftToErc20[
            0x892555E75350E11f2058d086C72b9C94C9493d72
        ] = 0x2313E39841fb3809dA0Ff6249c2067ca84795846; // Nifty Dudes
        nftToErc20[
            0x7C40c393DC0f283F318791d746d894DdD3693572
        ] = 0xf961A1Fa7C781Ecd23689fE1d0B7f3B6cBB2f972; // Moon Cats
        nftToErc20[
            0x1DB61FC42a843baD4D91A2D788789ea4055B8613
        ] = 0x48Bef6bd05bD23b5e6800Cf0406e524b517af250; // Chubbies
        nftToErc20[
            0x09B9905A472Aa1D387c9C1D8D956afF5463837E8
        ] = 0x68F2161B023af02c23C0173FAd644D8A15d30F25; // Ape Island - Season 1
    }

    modifier isAuthorized() {
        require(authorized[msg.sender], "user not authorized");
        _;
    }

    function addAuthorizedUser(address user) external onlyOwner {
        authorized[user] = true;
    }

    function addNftToErc20(address nft, address erc20) external isAuthorized {
        require(nft != address(0), "addNftToErc20: empty nft address");
        require(erc20 != address(0), "addNftToErc20: empty erc20 address");
        nftToErc20[nft] = erc20;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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