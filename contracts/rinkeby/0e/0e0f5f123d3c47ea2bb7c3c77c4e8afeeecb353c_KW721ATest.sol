// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
//import "./Strings.sol";

/*
 *           =%*+.                      ::                      .+*%+                 
 *            @@@@#:                   [email protected]@-                   .*@@@@.                 
 *            .*@@@@#-         +-     [email protected]@@@=     :+         :#@@@@*.                  
 *              .#@@@@%-       [email protected]@#   [email protected]@@@:   *@@+       -#@@@@#:                    
 *                :%@@@@%= -##= %@@[email protected]@@@[email protected]@% =##= -%@@@@%-                      
 *              .##.-%@@@@@=    :@@@@@@@@@@@@@@@@:    =%@@@@@=.*#.                    
 *              :@:   [email protected]+----:   +%*+=-:..:-=+*#*   :[email protected]+   [email protected]                    
 *              :@:     [email protected]@%#*+=                  =+*#%@@=     [email protected]                    
 *              [email protected]     -.  :.    -*@@*.  [email protected]@*-     :. .-     :@:                    
 *               @+  .+#%@@%-   [email protected]@@@@@@##@@@@@@@*   :#@@%#+.  [email protected]                     
 *               *% :@@@#=:=*  [email protected]#@@@@@@@@@@@@@@#@=  +=:=#@@@- ##                     
 *               :@:[email protected]@--*@@.   .. .=%@@@@@@%=. ..   .%@#-:@@[email protected]                     
 *                ## %=%@@*=:  *@@**=:@@@@@@:=+*@@*  :=*@@%[email protected]*%                      
 *                [email protected] %@@@@#   :@@@@@#@@@@@@#@@@@@:   *@@@@% :@:                      
 *                 [email protected][email protected]@#-  =*  +%[email protected]@%@@@@%@@+%+  ++  -#@@+ @+                       
 *                  #% #-  [email protected]@+   .%@@*:..:*@@@.   [email protected]@+  :* ##                        
 *                   %*   %@@%.#+ [email protected]@@@@[email protected]@@@@+ =#.#@@%   *%                         
 *                    %* :@@@#@@@  +%*--++=-+%*  @@@#@@@- *%.                         
 *                     ## [email protected]@@+#@    [email protected]@@@@@+    %#[email protected]@@= *%                           
 *                      *%.:%: @*    *@@@@@@*    [email protected]%-.##                            
 *                       [email protected]   =% .+   :##-   =: #=   [email protected]+                             
 *                     +#..%*   :::@-        :@-.-   *%: *+                           
 *                 .:.#@%-  =%=    @@++.  .*[email protected]@.   -%+  :%@%.:.                       
 *               %@@@@=::    .*%:  [email protected]@@@::%@@@*  :%#.    ::=%@@@@.                    
 *              [email protected]@@@@@        :%#: -=%@@@@@=- .*%:        @@@@@@*                    
 *              [email protected]@@@@+          -%#:  [email protected]@=  :#%-          =%@@@@=                    
 *                ..               :#%=    -##-               ..                    
 *                                   [email protected]*[email protected]*.                                         
 *                                      -=                                            
 */


contract KW721ATest is Ownable, ERC721A, ReentrancyGuard {

    uint256 public constant MAX_TOKENS = 8888;
    uint256 public totalSupply2 = 0;
    uint256 private maxPhaseTokens = 0;
    uint256 private walletMintLimit = 2;
    mapping (address => mapping(uint256 => uint)) phaseWalletList;
    address[] private allWallets;
    uint256 private phaseId = 1;
    bool private phaseRestricted = true;
    bool private phaseOpen = false;

    string private baseURI2;
    uint256 public constant RESERVED_GENESIS_TOKENS = 40;
    uint256 public TOKEN_PRICE = 0.08 ether; // 0.08 ETH
    uint256 public tokensMinted = 0;
    uint256 public tokensBurned = 0;

    address accessAuthority = 0xFbABC9E7651fA9eC84d85d590Cc6f14C29DD026a;


    constructor() ERC721A("KWTest721A", "KW721A", 100, 8888) {}


    //Config
    function getConfig() public view returns(uint256, uint256, uint256, uint256) {
        return (phaseId, maxPhaseTokens, walletMintLimit, TOKEN_PRICE);
    }

    //Accessor
    function isValidAccessMessage(uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        return accessAuthority == ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            ), v, r, s
        );
    }

    //Warrior Mint

    function rawMint(uint256 numberOfTokens) public payable {
        _safeMint(msg.sender, numberOfTokens);
    }

    function payMint(uint256 numberOfTokens) public payable {
        require(TOKEN_PRICE * numberOfTokens <= msg.value, "Not enough ETH for mint");
        _safeMint(msg.sender, numberOfTokens);
    }

    function warrionMintPrecheck(uint256 numberOfTokens) private {
        require(numberOfTokens <= walletMintLimit, "Cannot mint more than the max mint limit");
	    require(tokensMinted + numberOfTokens <= MAX_TOKENS, "Not enough tokens left to mint that many");
        require(tokensMinted + numberOfTokens <= maxPhaseTokens, "Not enough phase tokens left to mint that many");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, "Not enough ETH for mint");
    }

    function warriorMint(address to, uint256 numberOfTokens) private {
        _safeMint(to, numberOfTokens);
        //totalSupply += numberOfTokens;
    }

    //PHASE MINT

    function preMint(uint256 numberOfTokens, uint8 v, bytes32 r, bytes32 s) public payable nonReentrant {
        require(phaseRestricted, "Minting is not active");
        require(isValidAccessMessage(v, r, s), "Mint access not granted!");
        processMint(numberOfTokens);
    }

    function publicMint(uint256 numberOfTokens) public payable nonReentrant {
        require(phaseOpen, "Minting is not active");
        processMint(numberOfTokens);
    }

    function processMint(uint256 numberOfTokens) private {
        require(phaseWalletList[msg.sender][phaseId] + numberOfTokens <= walletMintLimit, "You can't mint over your limit!");
        warrionMintPrecheck(numberOfTokens);
        warriorMint(msg.sender, numberOfTokens); 
        phaseWalletList[msg.sender][phaseId] += numberOfTokens;
    }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  // OWNER FUNCTIONS

    function setAccessAuthority(address addr) external onlyOwner {
        accessAuthority = addr;
    }

    function setPhaseOpen(bool open) external onlyOwner {
        phaseOpen = open;
    }

    function setPhaseRestricted(bool restricted) external onlyOwner {
        phaseRestricted = restricted;
    }

    function setPhase(uint256 id, uint256 maxTokens, uint256 walletLimit) external onlyOwner {
        phaseId = id;
        maxPhaseTokens = maxTokens;
        walletMintLimit = walletLimit;
    }

    function setPrice(uint256 price) external onlyOwner {
        //in wei
        TOKEN_PRICE = price;
    }
}