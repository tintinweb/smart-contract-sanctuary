/**
 *Submitted for verification at BscScan.com on 2021-11-28
*/

// File: https://raw.githubusercontent.com/binance-chain/bsc-genesis-contract/master/contracts/interface/IBEP20.sol

pragma solidity 0.8.10;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
// File: BlueFlokiAirdrop.sol

pragma solidity 0.8.10;




contract BlueFlokiAirdrop{



    address owner;

    IBEP20 bluefloki;

    uint256 payoutAmount;

 

    mapping(address => bool) eligibleWallets;



    constructor(){

        owner = msg.sender;

        bluefloki = IBEP20(0x7aD8383Ac98F20B23f133160D9634C22931dD24E);

        addWallets();

        payoutAmount = 9009009009009009000; // We have 111 eligible wallets

    }



    function addWallets() internal{

        eligibleWallets[0x70701C60D94af91CB64931710Cc6c1D912Cb9Fec] = true;

        eligibleWallets[0x66008f1fEefEdeF0d2788eE938a76f51D852366B] = true;

        eligibleWallets[0x30B856eDaCA4f4d2B25aB904A3D28C1E18263158] = true;

        eligibleWallets[0x18b102c112553ee54ECD162404DBE3b8A3b9B749] = true;

        eligibleWallets[0x28BDC903E1f75863e1dec995285E8B2A08F021F1] = true;

        eligibleWallets[0x4295B281512ED6078a37aDDa855878fa23B46D76] = true;

        eligibleWallets[0x67801595583E0385d9130CaC22b019421bC3EDFA] = true;

        eligibleWallets[0x25DFA10bcf44b6020e8644EfF8DD2fa510283e44] = true;

        eligibleWallets[0xfD9Efb2cB9eF73Dd4bFdDa78f5fe0E9f027f9353] = true;

        eligibleWallets[0x4c53ED3037dea5e08e85B5d03B83a59b3AcB29Fa] = true;

        eligibleWallets[0x8230b13E37a3a8EE5BD24Ca399Ed8db0Dd397a59] = true;

        eligibleWallets[0x04f352dd84Fa8eab2bF80D58356D417B3c044c9D] = true;

        eligibleWallets[0x15b59c54D383b1A018F33cA17A94f7e5e09F3180] = true;

        eligibleWallets[0xc948407d505cFcD0f95E435fD73D7fcfEc65357D] = true;

        eligibleWallets[0x3D11D0dA96c4b3E0a9C902d38391fdF2Ff76A556] = true;

        eligibleWallets[0x370c6ffa5FBD9A57DAC2D20509032B70BaBA6577] = true;

        eligibleWallets[0x89cDc2470d49E0566685793F4eF42aC3D8C3F004] = true;

        eligibleWallets[0x463a3e0a0a01D60514C9D3207B1341512bb82cD7] = true;

        eligibleWallets[0xB8d68a1De6E5bc5af5a5bd1ce81157F0Fc269Cec] = true;

        eligibleWallets[0x5F6C4e3cbf5C5C3C4E8c29Cc9b5EeA08b33Bc716] = true;

        eligibleWallets[0xAE63889a4670778666C4f59BCE667B5Ec8707CF7] = true;

        eligibleWallets[0x1FC9d895D71C0B8499aB088A9D3281A09b79b3D3] = true;

        eligibleWallets[0x480563c617561867ef5244AB9a64312f99b36E66] = true;

        eligibleWallets[0x08ce1a94C6242AD49AC6312d68c938f28bB300aa] = true;

        eligibleWallets[0xa0a0797007Ea415B7A0C7b5bF52c71C36DaC4F38] = true;

        eligibleWallets[0x6619eF229FC395A54412F178328c23dD4311fAb5] = true;

        eligibleWallets[0xb04E2A1b39960D4136A63041e8B78f39788Ee7aa] = true;

        eligibleWallets[0x74a25832C4D71a44446EeF1f37AB4d35825CD0b6] = true;

        eligibleWallets[0xB57E6bfE1E468c86910A86859eC1860ba1397660] = true;

        eligibleWallets[0xA202dbb8f3ca0ACbe7f2e0Ef7d6FA6c9614Fa2FC] = true;

        eligibleWallets[0x9B4271b0b1eF4B2B417E6Df7949c043A02804089] = true;

        eligibleWallets[0x25D42aF33d88589078C288B0fe8b72e69e4d9164] = true;

        eligibleWallets[0x5cC175fd5700eCf1Cd33201a219B22AC60233AB3] = true;

        eligibleWallets[0xB2AA459C408c8ea137dbCF54D599CFB20D56FC96] = true;

        eligibleWallets[0xcDDA226af97eB299ce449CbA7f51315f42ADEBf6] = true;

        eligibleWallets[0x472814F6646331Eb45eF186b8056d5AD363fFfC4] = true;

        eligibleWallets[0xe8E1Cd42b1f865c2d78A9E63b4492D4E20237B5E] = true;

        eligibleWallets[0x4786a72601b3dc0dBD079c5B3327dc968BFed6A6] = true;

        eligibleWallets[0x0d48116D1Cb4a79aE04bdCcBFa510fCdF1273351] = true;

        eligibleWallets[0x6C1386A259e0c3B054040efA3BfE6dB62C575863] = true;

        eligibleWallets[0x41D1bb3551ab5845EA85973b833426BE01e59DDD] = true;

        eligibleWallets[0x142Bc3c65054669909948E6e238798e423627413] = true;

        eligibleWallets[0x32258f9bcfC614BB2c2Ec7053195a3f7aa782966] = true;

        eligibleWallets[0x0cfD113F482A6E14b0F0C551eD65eC5BD569eB9A] = true;

        eligibleWallets[0x1F3877E33AAEf3F11de0E72DA9ABa3ebd1e0Cb5A] = true;

        eligibleWallets[0xf26422de029Ee956E193F29e4C68d0B4799e361A] = true;

        eligibleWallets[0xA2b5e00E6066f7e7f2Aa4068f06Bc1C07c39418B] = true;

        eligibleWallets[0x6eE5092746A472c4D55bEe424f040919f9407Eb9] = true;

        eligibleWallets[0xB3A685ea90953B0dAddE2201ACefe0AAD3eA90d1] = true;

        eligibleWallets[0xD02a5d281966D42A6CB92f680DaE8E8bC733b54a] = true;

        eligibleWallets[0xd4124c7a158412108c769B66931d7E3e90fa5cfd] = true;

        eligibleWallets[0x4ef1f87b5B8042d61361De3cE33dcE1830ADc098] = true;

        eligibleWallets[0x8098BafB87f7a3C797183C8E04a2Be30a9c9e516] = true;

        eligibleWallets[0x09E3E36bc6cB8F48F5d787CAd782e2932fBfe4c8] = true;

        eligibleWallets[0x26B255DD6A9ec4d78539219DC0D651cd02bf556a] = true;

        eligibleWallets[0xB12BefeCD98331Bf740051421D9b311c7373A1c0] = true;

        eligibleWallets[0x88B04E6584f9559587C50C42f7Cc85028A0041bA] = true;

        eligibleWallets[0xfFCd5140aAC66933A0D09d911ECe079721822A1E] = true;

        eligibleWallets[0xf31F14767c053a5a648D79dD83622822050235B3] = true;

        eligibleWallets[0x02b278da1D5a5f0Fd8AD389E242A561E6F8d17A7] = true;

        eligibleWallets[0x92C452A666BA1e3AdC03cDD3848CE9F5D4116d68] = true;

        eligibleWallets[0xa8A8662b5Bc9a25330013Da17a0C9D434C616184] = true;

        eligibleWallets[0xa9C7123C86a1517796D09a1586988C6f7Af303a2] = true;

        eligibleWallets[0xe17c558EeCC436792158F39200a20AA5efF66882] = true;

        eligibleWallets[0xA55F7204eD9f67F59Ef4a607204091659a470dfA] = true;

        eligibleWallets[0x653e92Cd95e371d95bDb1c25E033cCcE73D7994A] = true;

        eligibleWallets[0xF4952c70912712ACD9EDBFB3a2869e1a39cC3733] = true;

        eligibleWallets[0x1d74434A2372A179Ff115fa5aeA6269FEdB038db] = true;

        eligibleWallets[0x995637350069b0df35826F74c6ab323Ac394990d] = true;

        eligibleWallets[0x926D9dd3b473d5df5108c985c89bd897C01F6FeF] = true;

        eligibleWallets[0xa8a10F980d02F9B22a51A5F8577375Cf43D022F5] = true;

        eligibleWallets[0x9FFEdD8ea6D4E2ebe39bB58fcAa3a533588E750c] = true;

        eligibleWallets[0x65B42748AE0f4FD122b2075b9c21c8035935854d] = true;

        eligibleWallets[0xd52BaAD8C087B91011E501BBd8e1F0dB54C27851] = true;

        eligibleWallets[0x884eea0fC5C090D57B695FA26e5978b9f13EdEDA] = true;

        eligibleWallets[0xca98D24bc4678E0698613666aCC3e91a71cf0834] = true;

        eligibleWallets[0x7877D5541b1c26E9DD8d9e428a07E52E433dC47b] = true;

        eligibleWallets[0x7097E9FA1335358D90C93C7e260c6f76ee72568C] = true;

        eligibleWallets[0x6C0a78b6C4F8325cf9c95fbCFB782D6Cb8af0447] = true;

        eligibleWallets[0x33faD47DeaD5a3Aea35956cA10B644971953475a] = true;

        eligibleWallets[0xEE074aB39a06Ae5753Fd4E30fCC993Efe6aEB432] = true;

        eligibleWallets[0x19027098ED28Be18C1568Ebd418c83C4d5EA95cA] = true;

        eligibleWallets[0x41F6Ca782F285dFE96CA638e81BB65229E63AcAa] = true;

        eligibleWallets[0xE58bf933c5F45d515b37E9589cf4235aE405Fd1D] = true;

        eligibleWallets[0x0aa0c81e18cC5E993BcB6850AAF666e1890D94e0] = true;

        eligibleWallets[0x6A7Eb3fA1e8d16b551C328A63bA4EfF789B2B5B2] = true;

        eligibleWallets[0xB60271c20F9FDeD672ACB7f11D8E668442169d8F] = true;

        eligibleWallets[0xe192B9Ffb58766959DdE7A1B07e1A81069890992] = true;

        eligibleWallets[0x7CFf15f614042bED3d604341107A0241728b4BC2] = true;

        eligibleWallets[0xc2935dDb5a2893f6D0F29dd5E59C11bD6aa5A5a6] = true;

        eligibleWallets[0x8E7185fC0E729a7503789527Cfb4589794670f0f] = true;

        eligibleWallets[0xDBD1fcDa8967B1c533975b2Edf7D5cA81CAfdce9] = true;

        eligibleWallets[0xC0AA0B735a045D8C4CdDb840F1373e1799f4A2eF] = true;

        eligibleWallets[0xC0AA0B735a045D8C4CdDb840F1373e1799f4A2eF] = true;

        eligibleWallets[0xe3AF125Ef9E562091DEa6A39e99593e49e0Dd377] = true;

        eligibleWallets[0x9d78Eb25d76EB69BAcb5c58984F5b6f9587Cd9CB] = true;

        eligibleWallets[0x67B49995A32217662c75D5B06C27c788db0908d5] = true;

        eligibleWallets[0x741dEB06E541e51e709c4a7a91C3751d259AcE85] = true;

        eligibleWallets[0xEcdcbb3C93A11EdF2D92EDbe4356ECdAF0575AFA] = true;

        eligibleWallets[0x5b9aB34322200A1141E338b0888aC6CCb4B73771] = true;

        eligibleWallets[0x66293F751071D9ce79923E1b5fD389eb51C992DB] = true;

        eligibleWallets[0x6b2318163AC6C3564Aa343fCF9BbDE1CF1EA282e] = true;

        eligibleWallets[0x438A212cCeF1E6fA4939660bb9e6f1a5A80f12AF] = true;

        eligibleWallets[0x2ae107d5506Fec8e0d144f02a0d1ad295FBb5d8f] = true;

        eligibleWallets[0x506Afc03D801c60e8eD723A88ddc2Aeb7dbbF292] = true;

        eligibleWallets[0xe4232646b7aD1fD379d0B58f4f93356472DDEBe6] = true;

        eligibleWallets[0x1f15c89e7bCf5b756fc701E25Dd3d780B147c508] = true;

        eligibleWallets[0xE28c8336a6D138E90b053640128a75Ae54CE89Fc] = true;

        eligibleWallets[0x5036c9B678e2BB26F17398232E249f298AaDB49F] = true;

        eligibleWallets[0x9CEc6cFCa85b0E0A2f65f5627C835b764d68563E] = true;

        eligibleWallets[0x5CB89De1c8C2dB628799605dBD399Ba3462BFD4d] = true;

        eligibleWallets[0xb04E2A1b39960D4136A63041e8B78f39788Ee7aa] = true;

    }



    function claim() public{

        require(eligibleWallets[msg.sender] == true, "You cannot claim the airdrop!");

        eligibleWallets[msg.sender] = false;

        bluefloki.transferFrom(owner, msg.sender, payoutAmount);

    }



    function isEligible(address wallet) public view returns (bool){

        return eligibleWallets[wallet];

    }



}