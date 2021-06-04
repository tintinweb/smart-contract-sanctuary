// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Presale is Ownable {
    IERC20 token;
    string public constant info = "ETH2SOCKS Presale contract. This is only for DEFISOCKS holders.";
    uint256 public constant tokensPerEth = 25; //num tokens per ether
    bool private initialized = false;

    mapping(address => uint256) public maxContributions; // the allowed list of contributors and max they can buy
    mapping(address => uint256) public contributions; // the currently used contributions


    modifier whenSaleIsActive() {
        assert(isActive());
        _;
    }
    constructor() {}

    function startSale(address _tokenAddr) public onlyOwner {
        require(initialized == false);
        token = IERC20(_tokenAddr);
        token.approve(address(this), 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        initialized = true;
    }

    // TODO optimize this for the next edition!
    function addWhitelist() public onlyOwner {
        maxContributions[parseAddr('0x9234dA5B588A8FE47DfEb9a7852d49399CfB5a94')] = 3 * 10 ** 18;
        maxContributions[parseAddr('0xe8C0C83C181AACdab4f48624B5574CC88aD8E840')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xA1bD817e13ED6Bb524ED491cff76C83aFEC773Ac')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x0BD258D220c2524ca9992E873b03c1F556e3A385')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x354F38E5b57AB49F09A102cCB7E57E3Ba1bFaa5B')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xa29FDDEc9C36BDD680D3f5867735ff8949a7F15D')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xca1B8F95046506fdF2560880b2beB2950CC9aED6')] = 3 * 10 ** 18;
        maxContributions[parseAddr('0x5B93FF82faaF241c15997ea3975419DDDd8362c5')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xa5725a5211fdf7eEF802f31D190074BAfD5AdFCF')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x0027D58331121eFa6cfd229291745de2fEeabF38')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x61311200F273E2d594f7C0AEaAb5C80F0B7840c9')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x1c385edF4B687Db1472506447348A9E62E1e5EdB')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x5ea7ea516720a8F59C9d245E2E98bCA0B6DF7441')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x3E099aF007CaB8233D44782D8E6fe80FECDC321e')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x5E0158553598B40Ecc13A3B1f78ee96536E6D0Da')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x1F717Ce8ff07597ee7c408b5623dF40AaAf1787C')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x4C955926022a8D7d281eac1Cb3Dc8714A84C3208')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x9d2773e66d41a28CAE8eBbdBB7d396Fe51Ae03De')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x19Eb7FfDcD670Ca917110Bd032463120a5E58C8E')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xb4022Ef3AaEE8C191192236202457CFc7f97Ee01')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x56a8708C31D813FEA9767dE2F0917967c07B167e')] = 3 * 10 ** 18;
        maxContributions[parseAddr('0x7c9932eEd5Aa0604FF417B2372B0AA76C5971bD3')] = 3 * 10 ** 18;
        maxContributions[parseAddr('0x95B5FEbE06b06baBE2d22469f5A9397B2417Fc23')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x9B921faD875b06183d3992A125026c89915D71F6')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xD90C5c640B518f17dFD74c2e6cFF3Bb779179a43')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xb757872560aE94D385Ac274CBEd43168d91D46d7')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xE4F60f6Fe872d5b910E72A11D09cdcf3780d20dB')] = 3 * 10 ** 18;
        maxContributions[parseAddr('0x0b2d429E9C0EbDf30fEb86e950080C2f4017c56e')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x7f98B58E2980Ba5D8Dba2439FBaAA315921eCb14')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x292b78a5AD6214971c0ec79Cb9d7eb3Cf20957Fb')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x8B68314eaDA9D4ba43C6E585f52a39AdEfc57839')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x4ad368bE4A965916FDb7812D6bBeA894Ad20b9AD')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x848F11E9c468be9EF6bF5F1Daa742e6ADF25D7A7')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x11B1785D9Ac81480c03210e89F1508c8c115888E')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xF49fd35343ED954eDeD917AEa065dc8433c41493')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x86E578946D012B73c4B62070AF5c8c9e62D5a22A')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x09909F60366080884Af0721C3E37dFC094DCF2A9')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x3E3721D26D5B8612BCD6504696B82401b9951bA6')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xe2F8ffA704474259522Df3B49F4F053d2e47Bf98')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xC3ee900A4c8152d3F5C200Dd9C4470aC4AD17c7B')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x54067441D3E0591b34D29C11412765cF098c9475')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x6761BcAF2b2156C058634D9772F07374D6eDeF1d')] = 3 * 10 ** 18;
        maxContributions[parseAddr('0x2cb635670Bb92B6e45722F47b5849032d1ba5BF7')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x123432244443B54409430979DF8333f9308A6040')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x86a41524cb61edd8b115a72ad9735f8068996688')] = 3 * 10 ** 18;
        maxContributions[parseAddr('0x80a03DBf383c6FDD96FB95D1A24d63C7b6d02b08')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xe135f2F57732fA6f46C05D77Fb10300Eb1Ad0eF7')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xc51215C8ccb1EBB4303fC549F93B10A28d8Bd7D6')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x7eAfe3FBD6B784861E700C34Df3a1249ea8Ccf6e')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x66aeEAdD49026a7CFbdE0240A7B148F18966B7B7')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x4E4aac9Fe63D4Ff50C8b09D79448a6a39BAA97ef')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x645B28EE22d11384feFfb77BbC60C816456C093b')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xd522CD8cc56BAdBD1E9A84a9F726Dc87667Ad73A')] = 3 * 10 ** 18;
        maxContributions[parseAddr('0x0696CCA4f346552E2A8B822ce9AfA50413976A0F')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x333b1cB2936D4c460a497805fEc223C53c071938')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x749E1d15d3d461469BEc674575c2B07dd0dBEdeD')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x0998160bdF3Ff6D86A4E9D5c31e0eFC3Ca7e7D01')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x1ac396A3C0fF9c748D5E4D33E814e7F39DA68C88')] = 3 * 10 ** 18;
        maxContributions[parseAddr('0x1C467B19F4341D602B21BB09667B22b4eb43f86e')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xf9172446f3b6f0d027ef8f0a7fafa117ff5439c2')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xC8BA6C5472bcF982C88cb469C8785a3aF9B183c1')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x54c375c481f95ba43e2cEcd6Ef30631f55518f57')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x131975CA3E75259e60AFeb1cd34051A6804dA505')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xFFBE67042bF5F1bD11b6D9363E645c39782eCaA1')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x8c49C1D07579d778CAe5a567E77E5eE242169917')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xE9bb842F4535fB16aeFd984C4C06e97E55a50318')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x797BC498EdEE4357a16a1054dB0323CbD04C84c3')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xC6C9D802bC16d8746AAfCAc4781F9a8d442D585D')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xdc29ef538B3a2585ef6569eC63626f6DA40Ed3a2')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xC20f4DC033DDd766d69F1FE20c7b817bEF683e55')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x7Af7cA67AA827F58e0659C52a641aeE55a43B535')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x35623eA315322FF2618e7469c2E88415111B5444')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x45B2CEA7A3FBF2Ad972DB30d744724d5f04fA1f0')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x9325F1218cB6CAc2E5cd43baBDf988dADbCB1359')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xF2D54033190bbc5a322cb93c7B36c65670D63264')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x96b0425C29ab7664D80c4754B681f5907172EC7C')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x78873D7A53EDE849D9F82ad451Eb8bAFc77244e7')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x3Fe4F48938c2e5E99B2F804116C0Db382E21896b')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x55C44b2827D73BA7eDaFf4FE21f7E12F57e4115b')] = 3 * 10 ** 18;
        maxContributions[parseAddr('0xD9d87c5933f17AE865feBa60272F2e46B94b2344')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x7c712119b7f4F1A2e147425a939E1D5380b15DBa')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xce33Dbd4AFf2e53E1CA5e5568Db13e487666e5a6')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xbed058A4Bcc06338BdD214f150d25Ff3686E98Bc')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x93cfAd7BC7f8cc4d6dBa1dC26B2072057E28B455')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0xe1E63B61CeFf7bE948Ef058F4C3652119A006C37')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x1748789703159580520CC2cE6D1ba01e7359C44c')] = 3 * 10 ** 18;
        maxContributions[parseAddr('0x4495d7DBf117532698D9974Bd3Bc1fC3ba7C2d94')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x63aeA877b5d5FA234a1532F1b26A4F6d9051866e')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x3838433F63f4d4A24260F2485AACf5894ba7Bc93')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x23bc95F84BD43C1FCc2bc285fDa4Cb12f9AEE2df')] = 3 * 10 ** 18;
        maxContributions[parseAddr('0x324f660d42636232AeC4e1072994c5e322521CA9')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x3ce630f7Bc2e9FD32fAb844601795196E917DBDa')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x21d79c2Be4ab3de2802a60Da66f86D497D06102B')] = 3 * 10 ** 18;
        maxContributions[parseAddr('0xbb899870561D48e823DdfACFFa201dc20214a530')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x75aB4A0e0f68edDD2d22f329FBd1D893d9FB0ab6')] = 3 * 10 ** 18;
        maxContributions[parseAddr('0x5be0Fa14A0dD11A5F46A90317e219Fa086e95F61')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x3AC618DCb800E733B0C390a23DE4aA796927A9B7')] = 1 * 10 ** 18;
        maxContributions[parseAddr('0x6661C494f8Bb1847E9C94579C87A5122F22c7125')] = 1 * 10 ** 18;
    }

    function isActive() public view returns (bool) {
        return (
        initialized == true //Lets the public know if we're live
        );
    }

    fallback() external payable {
        buyTokens();
    } //Fallbacks so if someone sends ether directly to the contract it will function as a purchase

    receive() external payable {
        buyTokens();
    }

    function buyTokens() public payable whenSaleIsActive {
        require(msg.value >= 0.04 ether, "incorrect amount");
        require(msg.value <= 0.12 ether, "incorrect amount");

        uint256 numRequested = msg.value * tokensPerEth;
        uint256 numAllowed = getAllowedContribution(msg.sender);

        require(numAllowed >= numRequested, "Unable to purchase - overlimit");

        uint256 existingAmount = contributions[msg.sender];
        uint256 newAmount = existingAmount + numRequested;
        contributions[msg.sender] = newAmount;

        payable(owner()).transfer(msg.value);

        token.transferFrom(address(this), msg.sender, numRequested);
    }

    function tokensAvailable() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function endSale() onlyOwner public {
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transferFrom(address(this), payable(owner()), tokenBalance);
        //Tokens returned to owner wallet
        selfdestruct(payable(owner()));
    }

    function getAllowedContribution(address _beneficiary) public view returns (uint256) {
        return maxContributions[_beneficiary] - contributions[_beneficiary];
    }

    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor () {
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": false,
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