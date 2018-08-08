pragma solidity ^0.4.21;


/**
 
 
   ______   ______   __ __ __   ___   ___       __   __      ______      
  /_____/\ /_____/\ /_//_//_/\ /__/\ /__/\     /__/\/__/\   /_____/\     
  \:::_ \ \\:::_ \ \\:\\:\\:\ \\::\ \\  \ \    \  \ \: \ \__\:::_ \ \    
   \:(_) \ \\:\ \ \ \\:\\:\\:\ \\::\/_\ .\ \    \::\_\::\/_/\\:\ \ \ \   
    \: ___\/ \:\ \ \ \\:\\:\\:\ \\:: ___::\ \    \_:::   __\/ \:\ \ \ \  
     \ \ \    \:\_\ \ \\:\\:\\:\ \\: \ \\::\ \        \::\ \   \:\/.:| | 
      \_\/     \_____\/ \_______\/ \__\/ \::\/         \__\/    \____/_/ 



                        ▌ ▐&#183;▪  .▄▄ &#183; ▪  ▄▄▄▄▄
                       ▪█&#183;█▌██ ▐█ ▀. ██ •██  
                       ▐█▐█•▐█&#183;▄▀▀▀█▄▐█&#183; ▐█.▪
                        ███ ▐█▌▐█▄▪▐█▐█▌ ▐█▌&#183;
                       . ▀  ▀▀▀ ▀▀▀▀ ▀▀▀ ▀▀▀ 
 
  ██████╗  ██████╗ ██╗    ██╗██╗  ██╗██╗  ██╗██████╗    ██╗ ██████╗ 
  ██╔══██╗██╔═══██╗██║    ██║██║  ██║██║  ██║██╔══██╗   ██║██╔═══██╗
  ██████╔╝██║   ██║██║ █╗ ██║███████║███████║██║  ██║   ██║██║   ██║
  ██╔═══╝ ██║   ██║██║███╗██║██╔══██║╚════██║██║  ██║   ██║██║   ██║
  ██║     ╚██████╔╝╚███╔███╔╝██║  ██║     ██║██████╔╝██╗██║╚██████╔╝
  ╚═╝      ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝     ╚═╝╚═════╝ ╚═╝╚═╝ ╚═════╝ 
  
 
* HOW DOES THAT WORK?

* Every trade, buy or sell, has a 15% flat transaction fee applied. Instead of this going to the exchange,
* the fee is split between all currently held tokens! 
* 15% of all volume this cryptocurrency ever experiences, is set aside for you the token holders, as ethereum rewards that you can instantly withdraw whenever you&#39;d like.

COMPLETELY DECENTRALIZED, HUMANS CAN&#39;T SHUT IT DOWN.

We updated PoWH 4D graphics. 
We are grateful to weirdsgn.com and icondesignlab.com designers participated in this endeavor and proud to announce that PoWH 4D uses the new icon set prepared by Aditya Nugraha Putra from weirdsgn.com. 
Previous PoWH 4D icons are available as interface theme here: https://rarlab.com/themes/PoWH 4D_Classic_48x36.theme.rar 
"Repair" command efficiency is improved for recovery record protected RAR5 archives. Now it can detect deletions and insertions of unlimited size also as shuffled data including data taken from several recovery record protected archives and merged into a single file in arbitrary order. 
"Turn PC off when done" archiving option is changed to "When done" drop down list, so you can turn off, hibernate or sleep your PC after completing archiving. 
Use -ioff or -ioff1 command line switch to turn PC off, -ioff2 to hibernate and -ioff3 to sleep your PC after completing an operation. 
If encoding of comment file specified in -z<file> switch is not defined with -sc switch, RAR attempts to detect UTF-8, UTF-16LE and UTF-16BE encodings based on the byte order mask and data validity tests. 
PoWH 4D attempts to detect ANSI, OEM and UTF-8 encodings of ZIP archive comments automatically. 
"Internal viewer/Use DOS encoding" option in "Settings/Viewer" is replaced with "Internal viewer/Autodetect encoding". If "Autodetect encoding" is enabled, the internal viewer attempts to detect ANSI (Windows), OEM (DOS), UTF-8 and UTF-16 encodings. 
Normally Windows Explorer context menu contains only extraction commands if single archive has been right clicked. You can override this by specifying one or more space separated masks in "Always display archiving items for" option in Settings/Integration/Context menu items", so archiving commands are always displayed for these file types even if file was recognized as archive. If you wish both archiving and extraction commands present for all archives, place "*" here. 
SFX module "SetupCode" command accepts an optional integer parameter allowing to control mapping of setup program and SFX own error codes. It is also accessible as "Exit code adjustment" option in "Advanced SFX options/Setup" dialog. 
New "Show more information" PoWH 4D command line -im switch. It can be used with "t" command to issue a message also in case of successful archive test result. Without this switch "t" command completes silently if no errors are found. 
Every ethereum transaction is handled by a piece of unchangable blockchain programming known as a smart-contract.
No need to fear, you&#39;re only entrusting your hard-earned ETH to an algorithmic robot accountant running on a decentralized blockchain network created by a russian madman worth billions, enforced by subsidized Chinese GPU farms that are consuming an amount of electricity larger than most third-world countries, sustaining an exchange that runs without any human involvement for as long as the ethereum network exists
Welcome to cryptocurrency.
Your tokens are safe, or somebody would be yelling at us by now.

*/


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract PoWH4D { 
    // Public variables of the token
    string public name = "PoWH4D"; string public symbol = "P4D"; uint8 public decimals = 18; uint256 public totalSupply; uint256 public PoWH4DSupply = 800000; uint256 public buyPrice = 2000;
    address public creator;
    // This creates an array with all balances
    mapping 
        (address => uint256)    
            public balanceOf;
    mapping     
        (address => mapping 
            (address => uint256
            )
        ) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer
            (address indexed from, 
            address indexed to, 
            uint256 value
            );
    event FundTransfer
            (address backer, 
            uint amount, 
            bool isContribution);
    
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function PoWH4D() public {
        totalSupply = PoWH4DSupply * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;   
        creator = msg.sender;
    }
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
      
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function () payable internal {
	
	    uint amount;
        amount = msg.value * buyPrice;
        uint amountRaised;                                     
        amountRaised += msg.value;                            
        require(balanceOf[creator] >= amount);               
        balanceOf[msg.sender] += amount;                 
        balanceOf[creator] -= amount;                        
        Transfer(creator, msg.sender, amount);               
        creator.transfer(amountRaised);
    }

 }
 
 /*YOU SHOULD READ THE CONTRACT BEFORE*/