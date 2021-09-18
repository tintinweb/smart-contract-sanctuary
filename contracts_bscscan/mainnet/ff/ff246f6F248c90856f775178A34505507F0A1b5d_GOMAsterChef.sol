/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-28
*/

/** 

      /$$$$$$   /$$$$$$  /$$      /$$  /$$$$$$              /$$                          /$$$$$$  /$$                  /$$$$$$ 
     /$$__  $$ /$$__  $$| $$$    /$$$ /$$__  $$            | $$                         /$$__  $$| $$                 /$$__  $$
    | $$  \__/| $$  \ $$| $$$$  /$$$$| $$  \ $$  /$$$$$$$ /$$$$$$    /$$$$$$   /$$$$$$ | $$  \__/| $$$$$$$   /$$$$$$ | $$  \__/
    | $$ /$$$$| $$  | $$| $$ $$/$$ $$| $$$$$$$$ /$$_____/|_  $$_/   /$$__  $$ /$$__  $$| $$      | $$__  $$ /$$__  $$| $$$$    
    | $$|_  $$| $$  | $$| $$  $$$| $$| $$__  $$|  $$$$$$   | $$    | $$$$$$$$| $$  \__/| $$      | $$  \ $$| $$$$$$$$| $$_/    
    | $$  \ $$| $$  | $$| $$\  $ | $$| $$  | $$ \____  $$  | $$ /$$| $$_____/| $$      | $$    $$| $$  | $$| $$_____/| $$      
    |  $$$$$$/|  $$$$$$/| $$ \/  | $$| $$  | $$ /$$$$$$$/  |  $$$$/|  $$$$$$$| $$      |  $$$$$$/| $$  | $$|  $$$$$$$| $$      
     \______/  \______/ |__/     |__/|__/  |__/|_______/    \___/   \_______/|__/       \______/ |__/  |__/ \_______/|__/     
     
     
                                             ___________________ __________.___.___ 
                                            \__    ___/\_____  \\______   \   |   |
                                              |    |    /   |   \|       _/   |   |
                                              |    |   /    |    \    |   \   |   |
                                              |____|   \_______  /____|_  /___|___|
                                                               \/       \/    
                                                               
                                                               
                                                  *****************************
                                                        
                                                        
                                                    GOMAsterChef for TORII v2
                                                     
     
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        //_setOwner(_msgSender());
        _setOwner(0x1d3354FB678086Aa367FBb2BD30c05FADf558c9c); // set on deploy
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IBEP20 {
   
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	
    event Transfer(address indexed from, address indexed to, uint256 value);
	
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
   
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
	
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeBEP20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

contract GOMAsterChef is Ownable {
    using SafeBEP20 for IBEP20;
    
    struct UserInfo {
        uint256 amount;     
        uint256 rewardDebt; 
    }

    uint256 public lastRewardTimestamp;
    uint256 public accRewardTokensPerShare;
    uint256 public claimedRewardTokens;

    IBEP20 public immutable rewardToken;
    IBEP20 public immutable stakedToken;
    address private immutable stakedTokenOwner;
    uint256 public stakedTokenDeposied;

    uint256 public immutable minTokensPerSecond;
    uint256 public immutable maxTokensPerSecond;
    uint256 public tokensPerSecond;
    uint256 public minDepositAmount;
	
    uint256 private immutable taxPercent;
    	
    mapping (address => UserInfo) public userInfo;
    
    uint256 public immutable startTimestamp;
    uint256 public pausedTimestamp;
    bool public productionMode = false;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
	event Supply(address indexed user, uint256 amount);
	
    constructor() {
        stakedToken = IBEP20(0xAb14952d2902343fde7c65D7dC095e5c8bE86920); // GOMA
        rewardToken = IBEP20(0xfD053F9A52d2D74Aae83c28323CC7d2e2Fefb263); // TORII
        stakedTokenOwner = 0x21eFFbef01c8f269D9BAA6e0151A54D793113b45;
        
        minTokensPerSecond = 1000000000;
        maxTokensPerSecond = 10000000000000000; 
        tokensPerSecond = 250000000000000;
        
        startTimestamp = blockTimestamp();
        lastRewardTimestamp = blockTimestamp();
        
        taxPercent = 800; // 8%
        
        minDepositAmount = 1000000000 * 10**9; // 1000000000000000000 

        // owner set in Ownable constructor
        
        // redeposit from old contract ----------------------------------
        userInfo[0x1d3354FB678086Aa367FBb2BD30c05FADf558c9c].amount = 920000000000000000;
        userInfo[0xE92097c7D33A54E2018f09A5BD10dC8b827d4353].amount = 691732170817329550353;
        userInfo[0x7bD1502D71e122944b4230e66F1bC609C250dCC9].amount = 524303059651991052770;
        userInfo[0xc81a5fA8554B596695F368e37353f0F56D83f893].amount = 303600000000000000000;
        userInfo[0xC9a819ce1DF7525a9De59606cA11436Eb78b5189].amount = 874695381527231140958;
        userInfo[0xDF26c6b61aA30DE2EFfDb31C407B03376E638502].amount = 147303961081901646288;
        userInfo[0xF37eEFFA06bC9898A89eb80879F2b41ABA3ebE7A].amount = 3196641640468893851;
        userInfo[0x0f525222D872056a7913c8E69F789619aCBF0bAC].amount = 920000000000000000000;
        userInfo[0x0778d7185592720b58C1F639EFbEbC8b3FAA8257].amount = 655844158162979842486;
        userInfo[0x0ADf2fF8727d1915c42570B35C27A76E33d69c79].amount = 271818281219074672248;
        userInfo[0x96Eae9372117604d8829AeAe4ebBe7F27bBE89b0].amount = 3099585036989805048349;
        userInfo[0x4cE1D9a3A8bE1BEFf95096aEf09D1fA037779290].amount = 1600800000000000000000;
        userInfo[0xaaC3FFeaF863D3F1D35784344FDfeE2d0F48976C].amount = 160426085435981852074;
        userInfo[0xF371d770210aDC2057B0422df159e7224324d346].amount = 370958866087635169857;
        userInfo[0x58ca5EeD12880d11439Ae9e6371E31e7c0dcBAA6].amount = 392113937924349247058;
        userInfo[0x91113E561DBb2b6D303490096fB43aB5cC2E1505].amount = 1000000000000000000000;
        userInfo[0x07400eC4836E9C5a735032EF54310DB9D582d1B2].amount = 854411273798889812114;
        userInfo[0x4Aa759Ffdd4cDAc6b1D0E4fBc751204a01cBEb70].amount = 920000000000000000000;
        userInfo[0x670EC3Fff3F5AB79f1E61930430Ec57B509631B0].amount = 736000000000000000000;
        userInfo[0x4Ab922c7Fc7998879D10d20A045301DBfA8d64fe].amount = 957910056420316894357;
        userInfo[0x8cc15E12230572Cd5828B8327E8Db2A973A0fD71].amount = 313521607925642731110;
        userInfo[0x788d47DA11b108419D43aFe747cB13eA0c6F2dcd].amount = 1748000000000000000000;
        userInfo[0xe3f5c803B3F2f0E7A055bb035d202c8DEde5eb7F].amount = 258425382807023997974;
        userInfo[0x1BE27d90B9b9a97d1f815fc80E388049a3579300].amount = 1856528313927573320156;
        userInfo[0xF6D8545f77E6C5FBDf596f2f83C5a4fc98924E76].amount = 664660405433204059898;
        userInfo[0x96CD24CC869C04F6FfF1f5c2Efb985646eFc583e].amount = 331246617592320000000;
        userInfo[0xe6aAfEd3Ec5E020ED82fFdB086978dcb8c35c1ED].amount = 1236351336964958918188;
        userInfo[0xc438e3115EcF74B07cD4865EEA9E5957C0fDC3C4].amount = 268854458810760000000;
        userInfo[0x4808194271aBE55809912488be5AF2F8BAD95eAE].amount = 143931995645438292559;
        userInfo[0x1023E5A9D1eE255CBeF5aB8658e7cf23A13Ad820].amount = 284600656559880000000;
        userInfo[0xbdFCb9AA71AC50AF5b4E49303EEfDeDEAD4fBB10].amount = 542077957229840000000;
        userInfo[0x47285654b247dE48865554E5dEFaC91898fF38AB].amount = 529715938005704061515;
        userInfo[0xC830bA2f7510B10D7558835B118BA0A552BF4A0a].amount = 565726030356880000000;
        userInfo[0x6a68E52EB1086B1390065BC478E1dFD870620FBc].amount = 308247242444773138288;
        userInfo[0x397F605137152F37675b33382c2025D5462b8F44].amount = 858102363884515632490;
        userInfo[0x1Cb11d32F9f063173A194e0a78ACBAFd474217AA].amount = 90782007061093622543;
        userInfo[0xE30b6eDB575aA905f13ad4a23DA1C96CbBFBBf79].amount = 42314037225882331365;
        userInfo[0xa03640a7EFcbef7A806C0415ec994986c70b7B61].amount = 524822086256280000000;
        userInfo[0xDc89f5Bf59742a080089Db3C47bC9E1EBb55d7C1].amount = 405720000000000000000;
        userInfo[0x1cAA625838B8499C348F0351CF52EceAf6eCbac8].amount = 156518002754634147470;
        userInfo[0x8dd8866048C50A58C1b2bDF908cba59AcFC99c7a].amount = 159382439959077179481;
        userInfo[0xED811F2D15962BdAf050390457FD97914E086798].amount = 12383215750756160439;
        userInfo[0x827e0C6c4c2DF64cEF52b8A3709fca599322adfF].amount = 134455742689529733970;
        userInfo[0xFC4eC5AC4f1c37dBEf9dB906041D5Ce2ae86F719].amount = 95854751229492778609;
        userInfo[0xe1F4676CB2BCDe1F8a993678E9C5785A1C5F8420].amount = 222070149895800225444;
        userInfo[0xf7bEe90752dAe13ce75E98643F7D7b5a3B80D864].amount = 780695819266398223159;
        userInfo[0x5792d852cCdCAb3822F79A052d6bBD95Fc383755].amount = 208824342145665442637;
        userInfo[0x964c545fc9a30ca50e7a28B7aD5216EaC734a2f8].amount = 122782190110212166397;
        userInfo[0xD94A55B7575628d482Ae4e74e01eF49deE3D102c].amount = 89689650756169542582;
        userInfo[0x95Ba02dF3074C6C791482FfE299D6732A7111055].amount = 496859929441155213906;
        userInfo[0x77fdC37D6B21B01fE4A61100e5B642B26A1cAE32].amount = 271235893054235813893;
        userInfo[0x114A0B922381A391855CeAc0a44888f3FB9E9229].amount = 114741957405765369317;
        userInfo[0x42191E22544Df494694Ed34E342b6b8871882ecc].amount = 1016882647948541362604;
        userInfo[0x16E2E92BF850fCF96627c8eC31d643a085B38a38].amount = 361229475250189280100;
        userInfo[0xf38AD62a754620ffbA82E7528EC8Ab474Ff72788].amount = 4024435154781774744808;
        userInfo[0xB21f4A2dFca5C6C00f78338E7BA5A847587d6f30].amount = 43800452914579757544;
        userInfo[0x7Fd360aA3f12E93236dab623c8EC97B669eE2122].amount = 158287411328993844317;
        userInfo[0x4cBBB28e082366cf2d4088837f7F1B5df0c39762].amount = 175178590695756587947;
        userInfo[0x7f83978e057b52c8dC0E12B9d2f04Df3CE9Fd82a].amount = 716518836770982568643;
        userInfo[0x4d744FD121067821E49eF05089CEcea8e187dA65].amount = 460000000000000000000;
        userInfo[0x4820dDbc8dA1eef30531Cf50B4081bb42A2C6439].amount = 2656577724031920039213;
        userInfo[0x0860E82785a84AcAcEA6d2d7bf0a17724b44D0ad].amount = 365372066375298181955;
        userInfo[0x1b3F03AD716c6Db908b14DA634EC3ceD4Af38960].amount = 275088507426760000000;
        userInfo[0x7342D9501f039Bdf95Aa280EA7C1d09f7d747D95].amount = 44672202805421452275;
        userInfo[0x7EcAb74478eb2c776726d463Fde60115B7F87a90].amount = 219359506243893757360;
        userInfo[0x21d8EbdB3A710240d4E3Bee6FB668c92661F8bF8].amount = 79378854128152326257;
        userInfo[0x49daC4BF74fC4fDb7ECA80EC8c0F4f19bFE99D93].amount = 180753711367397427651;
        userInfo[0xFCaBd5F502B6DD0B9D7F08B93237668c309108b2].amount = 61640000000000000000;
        userInfo[0x364943B950C0C3e205ab530152B50e6Ac3b31fac].amount = 152217567110949768908;
        userInfo[0x1Ec1504Db07d71711Dd5308127d47828B68c51C4].amount = 106175675529439823042;
        userInfo[0x1Ecc74e5f4751b39D2aB537fb9440Ca0426EbC5c].amount = 170783235942607032822;
        userInfo[0x8F235C9662Cc4EcAfdcd144C799573339913a245].amount = 2997403623709629246614;
        userInfo[0xe7c860C5Ca54A60b20C1eDfcF3Dd1DdFFe40A030].amount = 1733846923641657799807;
        userInfo[0xA9531531db55e0218A2D2Dc90f517a2f1c05659f].amount = 85408370367797047579;
        userInfo[0xf2A63E572Ad5f5D0219861B9d2287Df6e85Bd2E3].amount = 50878259907722904035;
        userInfo[0x22bB4d2b8a127a3d57671837f24261514FC8b978].amount = 83512842006469905401;
        userInfo[0x8D043AA3F87842E8a38aEb2dE2FffAaBe7B20816].amount = 118059873441615594391;
        userInfo[0xF44665F3bd360e35E90529A0aa836AB5e8860Ab8].amount = 36864438282120000000;
        userInfo[0x347F83C14144D76645Ad66f65BfbeB0A2bB5f371].amount = 460000000000000000000;
        userInfo[0x167918f1DfC10837275C694C6e8B56f9923110fD].amount = 42780000000000000000;
        userInfo[0x4c1774f43b1DdA4e4b729c9c541c107fa6CB19c0].amount = 278688114365720000000;
        userInfo[0xB7425B21c0137f7F8613C81941051fC28Bbe46cb].amount = 20192073387430794781;
        userInfo[0x8c6B02F09728c48fE5fd55Cf2ce65778478D1456].amount = 138513099640920000000;
        userInfo[0x7970010f51616EC80734FD3a540bf514d54A87b9].amount = 999999999999999785014;
        userInfo[0x577369385dBa07c2950A17A2CA193b52747226a8].amount = 1656000000000000000000;
        userInfo[0xE81a14b75ee9E0815Bd17fFf956056700da0E360].amount = 552000000000000000000;
        userInfo[0xFBB03dfe60A75baEB2f9128731FEfB63FC60524A].amount = 1380000000000000000000;
        userInfo[0x6470bF7B65faA7b4c97458f0Cdc0BE6685233b3B].amount = 11474349818347056703820;
        userInfo[0x22B73a74257e3E1830b91Fb45c85BF16b467196F].amount = 184920193669200000000;
        userInfo[0x8f026daAa32B8a22884E5A8cFAF6Df5AC262c7E9].amount = 4585877283324819133;
        userInfo[0x06C98E047Bca41BE16Fae6ff38c3a0D43a1710E6].amount = 138000000000000000000;
        userInfo[0xeE43A70f29335f464B0Fe7D5098dFf2E0AA3ad05].amount = 853893563214386791357;
        userInfo[0x6b57524289969319A54F843059A0724d242260E2].amount = 840009451370495230824;
        userInfo[0x35a8671A68b8185Ca61ca80bcFF858576154ac1f].amount = 5332446534382342511;
        userInfo[0x3093Cf145cb375d8656A998466b4eab5c3F0a5ef].amount = 402047266094804463016;
        userInfo[0xb4b600F2FCb34122C1162E44125a5bE321287970].amount = 59380971073835914771;
        userInfo[0xa39063c809eCfA0Ba9ACFfa3a70664dB6B273E8c].amount = 147200000000000000000;
        userInfo[0x48bcf637B986BD65DBA916545871eEa34E77baED].amount = 248400000000000000000;
        userInfo[0x485566687722cF0031c8A2d2E053d0cA1EA78B4f].amount = 147200000000000000000;
        userInfo[0x0dD44ff3F651b99B96Ee88865632908ee11e4829].amount = 147200000000000000000;
        userInfo[0x6cfAc9a71f499d80C9a7A4b62B4941775E1C926D].amount = 147200000000000000000;
        userInfo[0x9E28E0CbF527B1609c89968F823a15d189A7f05a].amount = 147200000000000000000;
        userInfo[0x0DaC7665dBAf3eF1BBccacd5348d348AedAf7736].amount = 147200000000000000000;
        userInfo[0x1eA0195233225Bd9a15872d30C20B2B738Ae27dD].amount = 8997415654080000000;
        userInfo[0x18b9Da3F757220faF27fE60fB89C6B9962D610Fe].amount = 609894011939893033397;
        userInfo[0xED18e3b9Cb09eE80e2907FF0bDF340bD11d35615].amount = 49794490490855241318;
        userInfo[0xaB99361A9dd93189ee060F3AFb125AD02D8E56aB].amount = 43622485730524672313;
        userInfo[0xc462D27E3Beb669037867fCdE9c844DDc6210fDb].amount = 60967106523879794442;
        userInfo[0x2e18ECc86B9A3fC5A87C5c7CE0A73f956D9dC0E2].amount = 13473136531392888591;
        userInfo[0xFf1D283d853B7e2ce562a13F9d77706bA9576cA1].amount = 76159596916372254569;
        userInfo[0xA513C513AA65aE06668F87C3aFDcb35d4Fb9Ee66].amount = 32047692982128365649;
        userInfo[0xb468452c86F22cB30555Ab7d599BFEB9b7dC8999].amount = 606696357688227073411;
        userInfo[0xDb3b2755eA60cB96AF4E34Fb9AAb55acD82CEBf0].amount = 73584530490011545283;
        userInfo[0x69AF29dF0f5CC2327060bCB6A111Deefe9c47823].amount = 287881825483080000000;
        userInfo[0x4f63990274C978E1298CaDbce96510BE8aaa2086].amount = 460000000000000000000;
        userInfo[0xA5047bD474FAa0A166d3d74E0F672eCA04995B0C].amount = 41095744467950910924;
        userInfo[0xD0F5be8894b6b89AaE357A62438B64047eF8824C].amount = 17573067081037098120;
        userInfo[0xd7AD48DAF74313E7FfA6D2D34e3658EDAa731E13].amount = 4985562171761703063;
        userInfo[0x828707e8ee5C96bF1f378Af34515BA5aE3379a9e].amount = 897613674459106092213;
        userInfo[0x0b5b37b50A1FaAf1aF58617FBf9838503ECC2C71].amount = 42436349097962449218;
        userInfo[0xf5D59d37A20c6e764fDf05fAE0ecEc92d090378D].amount = 2070924695174676842;
        userInfo[0x4c8856526365f725064973BA8F0aD9b66684C3f3].amount = 42341968181858775026;
        userInfo[0xFaEbD609995A9b5Dc20b083030C5d7163EE855d6].amount = 25585436059545482348;
        userInfo[0xB5e898EB51F291EAAcC59E0E79A5b8cdc0D73F9b].amount = 19200000000000000000;
        userInfo[0x010D9237dcac08Ee1f416aFE45D5623c5CCe0A74].amount = 851031126068109171218;
        userInfo[0xf1498FD8ae6f60201B78F29fC65810C40359a575].amount = 56231175364808373068;
        userInfo[0x1D785f1e2261162958F2452315ab21B2227Bc727].amount = 140859251218586253177;
        userInfo[0x8ec41Ae14ED835eaAd94c6219236F8e1a4DBa609].amount = 250322042833369291679;
        userInfo[0x5Da96Adf876682238Cb5586CBF467b26744949e7].amount = 255908133707105000548;
        userInfo[0x9e0429dF5639ee2f3Eb1c6D936c9Ae0a4094bc8F].amount = 56805747170304813876;
        userInfo[0xcF7641E854018aB93871350b9Fd98FDa35ab630f].amount = 5518566993852502583;
        userInfo[0x46d46AB8b5a0fAe80c61D337d6Ad8D54b65A5719].amount = 52737258061214173575;
        userInfo[0xDCfA6a6Ae78329a9377f20E366ecf2BcCaf066C3].amount = 1040549573354965717006;
        userInfo[0x46aaf63B514c093Ee3Aa8809759A2807aC8Ea48E].amount = 52073298943946968442;
        userInfo[0x42ec720876B894B79F06525f9AD68d12980D5bdE].amount = 35812696639418413012;
        userInfo[0xdAdfdef90E457CDC5fEFb9f49ec6936e166b24Ee].amount = 13074463356624713590;
        userInfo[0x4c4ca1eE205F13b135f44Ed20fDF0adE2E8C56C3].amount = 57999578962803474104;
        userInfo[0xcebE1e34e541CF3BDd5B73A6C28e25716AB41cE5].amount = 3592791290439778855;
        userInfo[0x9FB70A5054c7ad67eB9Ed0CfB06032218c6A1fB4].amount = 191374713746614675145;
        userInfo[0x1cE7Fa63486cbBD86186242A2479F19BFD298601].amount = 233821819566104824752;
        userInfo[0x741D85A303E8AEc431F3d5CBEfd337F7bf1137Ca].amount = 92000000000000000000;
        userInfo[0xAE36F97Aa669f2d1678aa5cE838C7553cf8d5989].amount = 108560000000000000000;
        userInfo[0xDF754C6F7186Aecf010e5Cf03300D9eb78f137c2].amount = 41304638052731069678;
        userInfo[0x901A945C2B890d68794108773b96878fF03aEEc5].amount = 690000000000000000000;
        userInfo[0xfb288Ce0823b79A922EB22c48aFC77494D243dF4].amount = 49947547277749265386;
        userInfo[0x4BEB0104ED24Ac184cf840889dB64731B7Ee8fA5].amount = 301417543507501231510;
        userInfo[0x5C7A95FcEd5c6d1B39ec9C0aAeF71f59001cd5c2].amount = 27600000000000000000;
        userInfo[0x01bA28F16879960298ddeac16E6005215B8f0Cd1].amount = 1380000000000000000;
        userInfo[0x56D548a05482c61C2857D3e488A33d28194B8010].amount = 3506933992160196637;
        userInfo[0x0B5725694ACf2FC2caeFBBFCA801A438bA4692aa].amount = 47604757436130105588;
        userInfo[0x67F26Ab50a2021a6eDBFcDCDBA2A02801DEF30Cc].amount = 130705529376772710775;
        userInfo[0xBF4965e9af8DA21A4F9A4f672bF74729b048Ab50].amount = 40918326072305823858;
        userInfo[0x65Ee8C083f936143B21a4a99Bcc8497A38A9e28B].amount = 38532561051056010554;
        userInfo[0x291B2B05A58A10C8819d0d928F9F0Bb308F79A18].amount = 4323678641677147212;
        userInfo[0x09779d62fFD5BFdBA333B43ccED53DF87705D9FA].amount = 2490121210800000000;
        userInfo[0x556470dAc9f9a00214d4f16bc0C90AdD9bD80474].amount = 10120000000000000000;
        userInfo[0x4149504D2b73AFe60a4F2fb6E6C93fB211E7F2D2].amount = 737004983668862027571;
        userInfo[0x9d8ADAbC5AA47087B3a2d22fE2aD3c50E15a207A].amount = 137081173265880000000;
        userInfo[0x3016Fa0B07273Ed39dF64b8b104CB5885937EF10].amount = 180273516939280000000;
        userInfo[0x6a6bca70C63Cd673b1eE2E395e35033A8cA1bfAC].amount = 160821790309800000000;
        userInfo[0x48414811e68A60F49b3E08c19E1c146735F8a06A].amount = 1714300278560000000;
        userInfo[0x8694B68511231ce18828f7AB29d97cf7d2175ee1].amount = 2029657979760000000;
        userInfo[0xC8e32a7141718a07D98921669a1B009BB6AeBCCc].amount = 1996400000000000000000;
        userInfo[0x1eCfB730EF49b5503bc4c20a430AeBBb556cFFEf].amount = 12000000000040000000;
        userInfo[0xf093C7A15502F2752c7aE6272d192C8d56123370].amount = 136581132269563061399;
        userInfo[0xdB99F6D548254aCfB1b369EbF4BEF2764f488c38].amount = 450296343902404294599;
        userInfo[0xC79a4d7B4c2D7fbCABe5E78620A8a57575619Bb4].amount = 22185418365600000000;
        userInfo[0xB16D5dEf394b87eC2AC7dB1785698E3B7B44c9a9].amount = 98197042702520000000;
        userInfo[0xdd04A624178E82D98FE85C57EE55C857380b2254].amount = 130771423169396313831;
        userInfo[0x4D8086808C4fEBBc99E6782465470227EF54f094].amount = 146275234734914387128;
        userInfo[0x70468e56de573d6141838FeAcb98fB4552c48B11].amount = 156155051954775543586;
        userInfo[0xdFCb497d864aD89c4898d0D67cA5071985A90FA0].amount = 150068725179743991300;
        userInfo[0x8d8fDF6B5Bb427B304936979Ba32bc727F6F540b].amount = 1972694970244672412;
        userInfo[0xbb980Ff4fCa72CDDE06cbD730eBEb7B1d356f562].amount = 20566988784155430004;
        userInfo[0x88E6E10d1695389B00C618c85D4a8DC9f3743AbA].amount = 155556091175471366057;
        userInfo[0xD09669Ab446d4b8a3F0E7629fF6f054e21CF800C].amount = 600000000000000000000;
        userInfo[0xE677B1473E4ef105e30D28AcDcBFfb6903EEee0F].amount = 184000000000000000000;
        userInfo[0xA5DfA69bA6CdA7cd553ba8917F36Fd55087B8b41].amount = 337078221210664564771;
        userInfo[0x3a90B005C61c28a0Fdb8fe1067C88B273046d1E6].amount = 87917345266400422374;
        userInfo[0xE8429Fbf9DDd21d51b1e5AcC8eC5f8D368149fbc].amount = 23601024235040000000;
        userInfo[0x61d261f94f21A848e68F34b217c995c9CDa9300f].amount = 9200000000000000000;
        userInfo[0x8fA4A1983aDe38104a2F6BAbd63d42DcD85DFfb2].amount = 1110419946862320943;
        userInfo[0xc6984E737789d9b65E58aaF7C7FAc053785bDee5].amount = 19539587433560000000;
        userInfo[0x648533F8796c5EfD73A6C74d32eC454e99482028].amount = 272358069791514153649;
        userInfo[0xb835E7E32e7710Ef2F40cB4Aa57c1162Fb45E083].amount = 961582515251552627975;
        userInfo[0x1Bc96e23733877F29D93a68bc4EbE8614ed8698D].amount = 780422993621440000000;
        userInfo[0xE9F47904bD6F7F78bc1EC173225f9c3c3cA8d834].amount = 1936072811001784374;
        userInfo[0x4051A601B4c90d09ff5488BB6743F56882f2169b].amount = 970590063714414666752;
        userInfo[0xDEAb7E14FA998f4EeF87d0CFfB1062fE4A675386].amount = 534453730349320000000;
        userInfo[0x92a78Dab4C03C1F8831eB4C452EB9547e943170f].amount = 574374022364199950197;
        userInfo[0x6308FBaf45f09825C8c2283A8Fb0CEF81889aF9F].amount = 4600000000000000000;
        userInfo[0xe634872f991905a1201f4Cea8E91b829Cc65F307].amount = 142928952993293040659;
        userInfo[0xaf0c7F73DA9C97C9Aa43D6A94B814226C876CBaB].amount = 101452856999411673994;
        userInfo[0x149d3694b2b85A10207287434E47b433ca453658].amount = 3486344532542506390;
        userInfo[0x32ADc653c03dc89a9eB4F670c4e296a5540C7a25].amount = 737140834674135729915;
        userInfo[0xCA3a2EBdd62C2B3C726CbE5d1F13370a6f030edc].amount = 104770248271560000000;
        userInfo[0x31A130d4A02F1f09A2e6bF30D779dA7CF660DCeb].amount = 50806468058760000000;
        userInfo[0x9e2916e164C3F14f1EF3b8835Af913641956b420].amount = 313487356486574073154;
        userInfo[0x97E640FC1A34eF4Aaa76BF715c41c9f0829898Ac].amount = 9447873290800000000;
        userInfo[0x28EEDad012107596a4dAf104B2ce4c0c57dd4e47].amount = 3891156277073839234;
        userInfo[0x226c4158a63d6616Aaa91610334A333b6B6a92Ad].amount = 4098820045785851876;
        userInfo[0x03aC741BCCAA2B80A64fc16cf1b4a321E1a7d690].amount = 3759223001732786553;
        userInfo[0x2B6FF8bF87eB266C9cf0E1D33107dC40d885C2Bf].amount = 3878371583486102952;
        userInfo[0xdA7360c4A7ec54303477bc05dD1bCDECB77efEeD].amount = 38235453470624453877;
        userInfo[0xB0EAAC87b3034EEFB63782A3F0e642afFaDdFEFF].amount = 18969360610783706904;
        userInfo[0x0aE6E060387Ef321ac3aC8595c3A528EAE266296].amount = 23204142441360000000;
        userInfo[0x6afD7EC238dA7B55dc0e4FBbB217f5c17b8D07Fb].amount = 27151048289200000000;
        userInfo[0xCdf92BbA6CDEbe92Cf49D642DFCA26afb5180324].amount = 1695560098440000000;
        userInfo[0xDba4F5090b8Ca791357DBCe73BA95e3d2347D073].amount = 80798231390600000000;
        userInfo[0x4642E636e83bE7Cc7Bf2ae759f619b74D7d3654A].amount = 2814406153160000000;
        userInfo[0x5c53FC335cd45b6bd0BE722C10Ed3794a7b5Eb35].amount = 46000000000000000000;
        userInfo[0x60426e48011cfFE6a00e0BbeA319af10756Da40A].amount = 76351485081552489864;
        stakedTokenDeposied = 85478589340279655821502;
    }

    
    //
    function setRewardTokensPerSecond(uint256 _tokensPerSecond) external onlyOwner {
        require(pausedTimestamp == 0, "GOMAsterChef setTokensPerSecond: you can't set while paused!");        
        require(_tokensPerSecond >= minTokensPerSecond, "GOMAsterChef setTokensPerSecond: too low tokens, see minTokensPerSecond!");
		require(_tokensPerSecond <= maxTokensPerSecond, "GOMAsterChef setTokensPerSecond: too many tokens, see maxTokensPerSecond!");

        _updatePool(); 

        tokensPerSecond = _tokensPerSecond;
    }
    
    // 
    function setMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
        require(_minDepositAmount >= 1000000000000000, "GOMAsterChef setMinDepositAmount: 1000000000000000 wei is minimum!");
        minDepositAmount = _minDepositAmount;
    }

	// 
    function pauseOn() external onlyOwner {
		require(pausedTimestamp == 0, "GOMAsterChef pause: already paused!");		
		pausedTimestamp = blockTimestamp();
    }

	// 
    function pauseOff() external onlyOwner {
		require(pausedTimestamp != 0, "GOMAsterChef resume: not paused!");
		_updatePool();
		pausedTimestamp = 0;	
    }

    // Return reward multiplier over the given _from to _to block Timestamp
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        _from = _from > startTimestamp ? _from : startTimestamp;
        if (_to < startTimestamp) {
            return 0;
        }

		if (pausedTimestamp != 0) {
			return _to - (_from + blockTimestamp() - pausedTimestamp);      
		} else {
			return _to - _from;
		}        
    }
    
    // 
    function getMultiplierNow() public view returns (uint256) {
        return getMultiplier(lastRewardTimestamp, blockTimestamp());
    }
    
    // 
    function pendingRewardsOfSender() public view returns (uint256, uint256) {
        return pendingRewardsOfUser(msg.sender);
    }

    // 
    function pendingRewardsOfUser(address _user) public view returns (uint256 real, uint256 reflection) { // reflection - legasy (
        UserInfo storage user = userInfo[_user];       
        uint256 _accRewardTokensPerShare = accRewardTokensPerShare;      
		
		if (stakedTokenDeposied != 0 && user.amount != 0 && blockTimestamp() > lastRewardTimestamp) {
            _accRewardTokensPerShare = accRewardTokensPerShare + ((getMultiplierNow() * tokensPerSecond) * 1e12 / stakedTokenDeposied);
        }

        uint256 pending = (user.amount * _accRewardTokensPerShare) / 1e12;
        if (pending > user.rewardDebt) {
            real = pending - user.rewardDebt;
        } else {
            real = 0;
        }
		        
        return (real, reflection); 
    }

    //
    function getPending(UserInfo storage user) internal view returns (uint256) {
        uint256 pending = ((user.amount * accRewardTokensPerShare) / 1e12);
        if (pending > user.rewardDebt) {
            return pending - user.rewardDebt;
        } else {
            return 0;
        }
    }

    //   
    function userInfoOfSender() public view returns (uint256, uint256) {
		return (
            userInfo[msg.sender].amount, 
            userInfo[msg.sender].rewardDebt
        );
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        require(pausedTimestamp == 0, "GOMAsterChef updatePool: you can't update while paused!");
        _updatePool();
    }
    
    // Update reward variables of the given pool to be up-to-date.
    function _updatePool() internal {        
        if (blockTimestamp() <= lastRewardTimestamp) {
            return;
        }
        
		if (stakedTokenDeposied == 0) {
            lastRewardTimestamp = blockTimestamp();
            return;
        }
        
        accRewardTokensPerShare = accRewardTokensPerShare + ((getMultiplierNow() * tokensPerSecond) * 1e12 / stakedTokenDeposied);
        lastRewardTimestamp = blockTimestamp();
    }

    // 
    function deposit(uint256 _amount) public {
		require(pausedTimestamp == 0, "GOMAsterChef deposit: you can't deposit while paused!");
        require(_amount >= minDepositAmount, "GOMAsterChef deposit: you can't deposit less than minDepositAmount of wei!");

        UserInfo storage user = userInfo[msg.sender];

        _updatePool();
                
        if (stakedTokenDeposied !=0) {
            uint256 pending = getPending(user);
            if (pending != 0) {
                claimedRewardTokens = claimedRewardTokens + pending;
                safeRewardTransfer(msg.sender, pending);
            }
        }
                
        uint256 finalAmount;
        if (msg.sender == stakedTokenOwner) {
            finalAmount = _amount;    
        } else {
            finalAmount = _amount - (_amount * taxPercent / 10000);
        }

        stakedTokenDeposied = stakedTokenDeposied + finalAmount;
        
        user.amount = user.amount + finalAmount;
        user.rewardDebt = (user.amount * accRewardTokensPerShare) / 1e12;
        
        stakedToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, finalAmount);
    }

    // Withdraw staked tokens
    function withdraw(uint256 _amount) public {  
		require(pausedTimestamp == 0, "GOMAsterChef withdraw: you can't withdraw while paused!");
        require(_amount != 0, "GOMAsterChef withdraw: you can't withdraw 0!");
                
        UserInfo storage user = userInfo[msg.sender];        
        require(user.amount >= _amount, "GOMAsterChef withdraw: not enough funds");
        
        _updatePool();

        uint256 pending = getPending(user);
        if (pending != 0) {
            claimedRewardTokens = claimedRewardTokens + pending;
            safeRewardTransfer(msg.sender, pending);
        }
        
        uint256 finalAmount = _amount;

        if ((user.amount - _amount) < minDepositAmount) {
            finalAmount = user.amount;
            user.amount = 0;
            user.rewardDebt = 0;
        } else {
            user.amount = user.amount - _amount;
            user.rewardDebt = (user.amount * accRewardTokensPerShare) / 1e12;
        } 
        
        stakedTokenDeposied = stakedTokenDeposied - finalAmount; 

        stakedToken.safeTransfer(msg.sender, finalAmount);
        emit Withdraw(msg.sender, finalAmount);
    }
    
    // Withdraw reward tokens
    function claim() public {  
		require(pausedTimestamp == 0, "GOMAsterChef claim: you can't claim while paused!");

        UserInfo storage user = userInfo[msg.sender];
        require(user.amount != 0, "GOMAsterChef claim: user deposited 0");
        
        _updatePool();
        
        uint256 pending = getPending(user); 
        require(pending != 0, "GOMAsterChef claim: nothing to claim");

        user.rewardDebt = (user.amount * accRewardTokensPerShare) / 1e12;

        claimedRewardTokens = claimedRewardTokens + pending;
        safeRewardTransfer(msg.sender, pending);
        emit Claim(msg.sender, pending);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function withdrawEmergency() public {
        UserInfo storage user = userInfo[msg.sender];

        uint256 userAmount = user.amount;
        require(userAmount != 0, "GOMAsterChef emergencyWithdraw: nothing to withdraw");
        
        user.amount = 0;
        user.rewardDebt = 0;

        stakedToken.safeTransfer(msg.sender, userAmount);
        
        stakedTokenDeposied = stakedTokenDeposied - userAmount;
        
        emit EmergencyWithdraw(msg.sender, userAmount);
    }

    // Safe rewardToken transfer function.
    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = balanceOfRewardToken();
        if (_amount > tokenBal) {
            rewardToken.transfer(_to, tokenBal);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }
    
    // 
    function supplyRewardTokens(uint256 _amount) public {
		rewardToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Supply(msg.sender, _amount);
    }
    
    // 
    function supplyStakedTokens(uint256 _amount) public {
		stakedToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Supply(msg.sender, _amount);
    }
        
    // only in test mode
    function startProductionMode() external onlyOwner {
        require(productionMode == false, "startProductionMode: already stared");
        productionMode = true;
        _updatePool();
		pausedTimestamp = 0;
    }
        
    // only in test mode
    function withdrawAllStakedTokens() external onlyOwner {
        require(productionMode == false, "GOMAsterChef withdrawAllStakedTokens: allowed only in test mode");
        require(balanceOfStakedToken() != 0, "GOMAsterChef withdrawAllStakedTokens: nothing to withdraw");
        stakedToken.safeTransfer(msg.sender, balanceOfStakedToken());
    }
    
    // 
    function withdrawStakedRewards() external onlyOwner {
        require(balanceOfStakedToken() > stakedTokenDeposied, "withdrawStakedRewards: nothing to withdraw");
        uint256 amount = balanceOfStakedToken() - stakedTokenDeposied;
        stakedToken.safeTransfer(msg.sender, amount);
    }

    // 
    function withdrawRewardTokens(uint256 _amount) external onlyOwner {
        require(balanceOfRewardToken() >= _amount, "GOMAsterChef withdrawRewardTokens: nothing to withdraw");
        safeRewardTransfer(msg.sender, _amount);
    }
    
    //
    function balanceOfRewardToken() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }
    
    //
    function balanceOfStakedToken() public view returns (uint256) {
        return stakedToken.balanceOf(address(this));
    }
    
    //
    function blockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
     
}