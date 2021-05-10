/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity ^0.5.15;

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

contract UMADistributor {
    IERC20 private constant TOKEN =
        IERC20(0x04Fa0d235C4abf4BcF4787aF4CF447DE572eF828);

    function execute() external {
        TOKEN.transfer(
            0xdD395050aC923466D3Fa97D41739a4ab6b49E9F5,
            1871753314059431387958
        );
        TOKEN.transfer(
            0xB3f21996B59Ff2f1cD0fabbDf9Bc756e8F93FeC9,
            16286028614007598748
        );
        TOKEN.transfer(
            0x4565Ee03a020dAA77c5EfB25F6DD32e28d653c27,
            2474951192525506172
        );
        TOKEN.transfer(
            0x974678F5aFF73Bf7b5a157883840D752D01f1973,
            32434713068469988426
        );
        TOKEN.transfer(
            0x653d63E4F2D7112a19f5Eb993890a3F27b48aDa5,
            600087648671336907355
        );
        TOKEN.transfer(
            0x3F3B7D0f3Da05F6Cd44E9D35A9517B59c83AD560,
            11934592418934047050
        );
        TOKEN.transfer(
            0xB1AdceddB2941033a090dD166a462fe1c2029484,
            1712531798617691230527
        );
        TOKEN.transfer(
            0xc7777C1a0Cf7E22c51b44f7CeD65CF2A6b06dc5C,
            818578630076296650
        );
        TOKEN.transfer(
            0x8CC7355a5c07207ef6ee188F7b74757b6bAb7DAc,
            1899239439614751982
        );
        TOKEN.transfer(
            0xcA5db177f54a8D974AeA6A838F0F92489734451C,
            14574444536323966247
        );
        TOKEN.transfer(
            0xAC465fF0D29d973A8D2Bae73DCF6404dD05Ae2c9,
            11254698005274221058
        );
        TOKEN.transfer(
            0x1d5E65a087eBc3d03a294412E46CE5D6882969f4,
            17507308498013220610
        );
        TOKEN.transfer(
            0xB17D5DB0EC93331271Ed2f3fFfEBE4E5b790D97E,
            16673627151730002268
        );
        TOKEN.transfer(
            0xD2A78Bb82389D30075144d17E782964918999F7f,
            166736279768695715510
        );
        TOKEN.transfer(
            0x25125E438b7Ae0f9AE8511D83aBB0F4574217C7a,
            89901115791289715256
        );
        TOKEN.transfer(
            0x9832DBBAEB7Cc127c4712E4A0Bca286f10797A6f,
            9372400380196672881
        );
        TOKEN.transfer(
            0x20EADfcaf91BD98674FF8fc341D148E1731576A4,
            30531715664911778879
        );
        TOKEN.transfer(
            0x07a1f6fc89223c5ebD4e4ddaE89Ac97629856A0f,
            848102355748681779
        );
        TOKEN.transfer(
            0xe49B4633879937cA21C004db7619F1548085fFFc,
            11360842546556398185
        );
        TOKEN.transfer(
            0x1e6E40A0432e7c389C1FF409227ccC9157A98C1b,
            2823232330318462440
        );
        TOKEN.transfer(
            0xC45d45b54045074Ed12d1Fe127f714f8aCE46f8c,
            9408215484434742131
        );
        TOKEN.transfer(
            0x798F73c7Df3932F5c429e618C03828627E51eD63,
            855291525537070769
        );
        TOKEN.transfer(
            0x3942Ae3782FbD658CC19A8Db602D937baF7CB57A,
            2906599460655609813
        );
        TOKEN.transfer(
            0x3006f3eE31852aBE48A05621fCE90B9470ad71Fe,
            855643566247828011
        );
        TOKEN.transfer(
            0x744b130afb4E0DFb99868B7A64a1F934b69004C4,
            15083561953158455911
        );
        TOKEN.transfer(
            0x0990fD97223D006eAE1f655e82467fA0eC5f0890,
            14077991076578138426
        );
        TOKEN.transfer(
            0x72Cf44B00B51AA96b5ba398ba38F65Cf7eFfDD05,
            225767700579872329131
        );
        TOKEN.transfer(
            0x96b0425C29ab7664D80c4754B681f5907172EC7C,
            13986842634569635122
        );
        TOKEN.transfer(
            0xbC904354748f3EAEa50F0eA36c959313FF55CC39,
            28407185919927852754
        );
        TOKEN.transfer(
            0xBE9630C2d7Bd2A54D65Ac4b4dAbB0241FfEB8DD6,
            15183599423182121313
        );
        TOKEN.transfer(
            0x663D29e6A43c67B4480a0BE9a7f71fC064E9cE37,
            151107990627198199381
        );
        TOKEN.transfer(
            0x966Cf5cd0624f1EfCf21B0abc231A5CcC802B861,
            83668320190365426941
        );
        TOKEN.transfer(
            0xCaea48e5AbC8fF83A781B3122A54d28798250C32,
            10882937581333999460
        );
        TOKEN.transfer(
            0x79D64144F05b18534E45B069C5c867089E13A4C6,
            28551913680252594832
        );
        TOKEN.transfer(
            0x1C051112075FeAEe33BCDBe0984C2BB0DB53CF47,
            251451583860050485586
        );
        TOKEN.transfer(
            0xA077bd3f8CdF7181f2beae0F1fFb71d27285034f,
            11851587014769949808
        );
        TOKEN.transfer(
            0xAABd5fBcb8ad62D4FbBB02a2E9769a9F2EE7e883,
            1782193636340387111
        );
        TOKEN.transfer(
            0xf0F8D1d90abb4Bb6b016A27545Ff088A4160C236,
            1047234137714674948
        );
        TOKEN.transfer(
            0xb15e535dFFdf3fe70290AB89AecC3F18C7078CDc,
            42958516818689187907
        );
        TOKEN.transfer(
            0xca29358a0BBF2F1D6ae0911C3bC839623A3eE4a7,
            13344011641187336847
        );
        TOKEN.transfer(
            0xa289364347bfC1912ab672425Abe593ec01Ca56E,
            1779200753393066429
        );
        TOKEN.transfer(
            0xfDf7F859807d1dC73873640759b2706822802529,
            844173685041052177
        );
        TOKEN.transfer(
            0x92EDED60a51898e04882ce88dbbC2674E531DEE4,
            1301743895152598010
        );
        TOKEN.transfer(
            0xb0e83C2D71A991017e0116d58c5765Abc57384af,
            44165528586891571955
        );
        TOKEN.transfer(
            0xffeDCDAC8BA51be3101607fAb1B44462c3015fb0,
            627369835443621796
        );
        TOKEN.transfer(
            0xfF3fc772434505ABff38EEcDe3C689D4b0254528,
            12281566566125739900
        );
        TOKEN.transfer(
            0x9ef0E7A0d3404267f12E6511f5b70FCA263AB62E,
            14650593994857847498
        );
        TOKEN.transfer(
            0x0154d25120Ed20A516fE43991702e7463c5A6F6e,
            25094818990099321171
        );
        TOKEN.transfer(
            0x8E97bA7e109Ba9063A09dcB9130e2f318ec0Da4e,
            1296942381928513857
        );
        TOKEN.transfer(
            0xDE41C393761772965Aa3b8618e9CD21A2b92ACD6,
            1080882124314957583
        );
        TOKEN.transfer(
            0x6ec93658A189C826A40664fbB4a542763c0a4BbB,
            919727126633549933
        );
        TOKEN.transfer(
            0x888592eab1bC578279c5f2e44e32a9FEFDB83799,
            2723824640322369872
        );
        TOKEN.transfer(
            0x1e44E34C1E07Ae17EB90fFDDB219db5E55B2776f,
            3220805468827783648
        );
        TOKEN.transfer(
            0x13928b49fe00db94392c5886D9BC878450399d07,
            4092353730348214693
        );
        TOKEN.transfer(
            0xA3f76c31f57dA65B0ce84c64c25E61BF38c86BEd,
            2913254548679416736
        );
        TOKEN.transfer(
            0x718FdF375E1930Ba386852E35F5bAFC31df3AE66,
            87243777093178433298
        );
        TOKEN.transfer(
            0x1Ec2C4e7Fff656f76c5A4992bd5efA7e7fF1A460,
            12375276716872199982
        );
        TOKEN.transfer(
            0xB71CD2a879c8D887eA8d75155ff51116178641C0,
            49337204341937470172
        );
        TOKEN.transfer(
            0x2f05c805d62c9B4D498d1f3E4fE42c612f0BE6B8,
            620038786659393482
        );
        TOKEN.transfer(
            0x30a73afACB7735e1861Ca7d7C697cD0b66f1b95A,
            24111368220887484195
        );
        TOKEN.transfer(
            0x5bd75fF024e79c5d94D36884622A65E6747E3D4F,
            6396528631555570761
        );
        TOKEN.transfer(
            0x71F12a5b0E60d2Ff8A87FD34E7dcff3c10c914b0,
            146962073074742880532
        );
        TOKEN.transfer(
            0x806388E04b7583a0148451A8ECd29A748b8fd584,
            4452087195975819311
        );
        TOKEN.transfer(
            0x1014440506b3384976F70f5dcbfC76f7C3cb53D6,
            1107963373569806458
        );
        TOKEN.transfer(
            0xdf3910d26836318379903A47bD26d0E05Cc9a0f5,
            631420365838833755
        );
        TOKEN.transfer(
            0xf56036f6a5D9b9991c209DcbC9C40b2C1cD46540,
            12999076851548240158
        );
        TOKEN.transfer(
            0x0C6AC3FCEA667fD6C62483cE1DBbce6f6ce0fB1f,
            54613116070328225
        );
        TOKEN.transfer(
            0x90B62a4ea00B214b6838799C11a9AE3585b32af5,
            112951099098854182
        );
        selfdestruct(address(0x0));
    }
}