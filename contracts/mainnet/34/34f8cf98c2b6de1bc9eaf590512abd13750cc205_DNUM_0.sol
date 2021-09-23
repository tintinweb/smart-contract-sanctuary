/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

/**
  * 
  * 
██████╗░███╗░░██╗██╗░░░██╗███╗░░░███╗░░░░░░░█████╗░
██╔══██╗████╗░██║██║░░░██║████╗░████║░░░░░░██╔══██╗
██║░░██║██╔██╗██║██║░░░██║██╔████╔██║█████╗██║░░██║
██║░░██║██║╚████║██║░░░██║██║╚██╔╝██║╚════╝██║░░██║
██████╔╝██║░╚███║╚██████╔╝██║░╚═╝░██║░░░░░░╚█████╔╝
╚═════╝░╚═╝░░╚══╝░╚═════╝░╚═╝░░░░░╚═╝░░░░░░░╚════╝░
 *
 **/

/**
 * * * * * * * * * * * * * * * * * * * * * * * * * *
 * 
 * hey traveler
 * 
 * you probably found this contract by chance or while stalking me or someone shared on twitter lol
 * 
 * let me introduce you d̢̞᷂́͆͆͠NUM_0
 * 
 * d̶̴̖͈̹̥͎͕̝͉̱͍͔̞̭̀ͨ̀́͗̂̓͆̂̾ͭ͌̑̎̌̕͞͞͞͞͞͞͡͞͞͞͞͞͞͞͞͞͞͞͞͞͞͞͝͞͞͞͞͠͞͞͞͞͞͞͞͞͞͞͞͞͞ͅ͏̷̷̢᷂̙̞᷂̖͓̗̃̿᷁͛̋̉͆̽ͦ̏ͥ̑̚͜͢͞͞͞͞͞͞͠͞͞͞͞͞͞͞͞͞͞͞͞͞͞͞͞͞͞͞͞͞NUM_0 IS THE FIRST EVER dNUM
 * 
 * dNUM (dECENTRALIZED-dECIMAL-dIGITAL-SOMETIMES dYNAMIC NUMBERS) are artificial decimal numbers, defined on smart contracts, living on-chains.
 * 
 * dNUM might look like pi or e. but they have their unique mechanics and properties.
 * 
 * first of all they are artificial and don't solve or discover anything about the universe
 * 
 * kinda useless
 * 
 * but there are more than 7 billion people alive on this planet, there will def be some people to find a use for this
 * 
 * cool thing about dNUM is that no one can say they don't exist. because they exist and have a numerical value.
 *
 * at random times, new numbers will be defined on new smart contracts (on several chains). in different forms, mechanics, limitations, interactions.
 *
 * dNUM_0 number value is static until contract state changes
 * 
 * dNUM_0 doesn't have properties a NFT have, like transfer. It is just a collaborative number
 * 
 * * * * * * * * * * * * * * * * * * * * * * * * * 
 * 
 * ###howto###
 * 
 * find an unclaimed decimal place (between 0 - 255)
 * 
 * declare your digit (0-9)
 * 
 * now your digit choice and wallet address are immortalized in dNUM foreva
 * 
 * if all 256 decimals are taken, dNUM_0 will be a constant from then on.
 * 
 * run render_dNUM_value_string() function to view the latest state
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * 
 * 
 * CALCULATION: 
 * 
 * sum of
 *     each digit (index starts from decimalpointlocation, which is 0 in dNUM_0)
 *          digit * ( 10 ** ( index * -1 ) )
 *
 *
 * eventually dNUM_0 value is gonna be somewhere between 0 - 9.9999999....
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * 
 * 
 * Decimal Point Location: 0th
 * Dynamic decimal point: No
 * Total Decimals : 256
 * Dynamic digits: No
 * Wallet Restrictions : No
 * 
 * * * * * * * * * * * * * * * * * * * * * * * * *
 * 
 * this is a proof of concept by berk aka PrincessCamel 
 * [ @berkozdemir - berkozdemir.com (website is super outdated) ]
 * 
 * i started thinking on dNUM concept in late 2019, which made me lose myself in blockchain technology
 * i prototyped different versions, tried different blockchains; made dynamic nfts, and a game like berryclub.io. never released final version of them
 * except one. actually there is an alpha nft contract on ethereum mainnet (my first smart contract ever), but metadata api and image generation is ded so token info can not be seen on marketplaces. it just stays there chilling.
 * so i owe this concept a lot for the things it taught me along the way
 * 
 * feel free to fork this smart contract or the idea to build your own version. 
 * or build something on dNUM contracts. 
 * pls do not forget to mention dNUM series when you launch something with it
 *
 * xoxo
 * 
 * 22/09/2021
 * 
 **/

pragma solidity ^0.8.0;


contract DNUM_0 {

    uint public constant totalDecimals = 256;
    
    uint public totalDecimalClaimed = 0;
    
    uint8 public decimalPointLoc = 0;

    string public constant def_prefix = "dnum_0 = ";

    enum Digit { ZERO, ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE }
    
    struct Decimal {
        Digit digit;
        uint8 loc;
    }
    
    Digit[totalDecimals] public digits; 

    address[totalDecimals] public addresses;

    mapping(Digit => uint8) public DigitCount;
    
    mapping(address => uint8) public addressCount;

    mapping(address => Decimal[]) public addressToDecimals;

    mapping(Digit => string) public DigitString;
    
    event decimalClaimed(uint8 location, Digit, address claimer);
    //̸̶̷̲̩̘̝̲̖̞͈̜̘̬͚̳ͪ̾̾ͪ̾̾ͪ̾̒̾ͪ̾̾ͪ̾̇̾ͪ̾ͣ̾ͪ̾̾ͪ̾ͪ̾ͪ̾̉̾ͪ̾̾ͪ̾̒̾ͪ̾̾ͪ̾̾ͪ̾̾ͪ̾̾ͪ̾̾ͪ̾̾ͪ̾᷄̾ͪ̾̾ͪ̾͑̾ͪ̾̾ͪ̾ͩ̾ͪ̾ͨ̾ͪ̾̾ͪ̾̾ͪ̾̾ͪ̾̾ͪ̾̾ͪ̾̏̾ͪ̾̾ͪ̾́̾ͪ̾̉̾ͪ̾ͭ̾ͪ̾ͬ̾ͪ̾͐̾ͪ̾̾ͪ̾̾ͪ̾̚͠͞ͅͅ
    constructor() {
        DigitString[Digit.ZERO] = "0";
        DigitString[Digit.ONE] = "1";
        DigitString[Digit.TWO] = "2";
        DigitString[Digit.THREE] = "3";
        DigitString[Digit.FOUR] = "4";
        DigitString[Digit.FIVE] = "5";
        DigitString[Digit.SIX] = "6";
        DigitString[Digit.SEVEN] = "7";
        DigitString[Digit.EIGHT] = "8";
        DigitString[Digit.NINE] = "9";
    }
    
    
    function isDecimalTaken(uint8 _loc) public view returns(bool) {
        return addresses[_loc] != address(0);
    }
    
    function areAllDecimalsTaken() public view returns(bool) {
        return totalDecimalClaimed == totalDecimals;
    }
    
    function claimDigit(uint8 _loc, Digit _digit) public {
        require(addresses[_loc] == address(0));
        digits[_loc] = _digit;
        addresses[_loc] = msg.sender;
        DigitCount[_digit] += 1;
        addressCount[msg.sender] += 1;
        totalDecimalClaimed += 1;
        addressToDecimals[msg.sender].push(Decimal(_digit, _loc));
        emit decimalClaimed(_loc, _digit, msg.sender);
    }
    
    function getDecimalsOfAddress(address _address) public view returns(Decimal[] memory) {
        return addressToDecimals[_address];
    }
    
    function render_dNUM_value_string() public view returns(string memory) {
        
        string memory text;
        
        for (uint i = 0; i < decimalPointLoc + 1; i++) {
            text = string(abi.encodePacked(text, DigitString[digits[i]]));
        }
        text = string(abi.encodePacked(text, ","));
        for (uint i = decimalPointLoc + 1; i < totalDecimals; i++) {
            text = string(abi.encodePacked(text, DigitString[digits[i]]));
        }
        
        return text;
        
    }
    
    function render_with_definition_prefix() public view returns(string memory) {
        return string(abi.encodePacked(def_prefix, render_dNUM_value_string()));
    }
    
    function getDecimalsAsArray() public view returns(Digit[totalDecimals] memory) {
        return digits;
    }
    
    function getAddressesAsArray() public view returns(address[totalDecimals] memory) {
        return addresses;
    }
    
}