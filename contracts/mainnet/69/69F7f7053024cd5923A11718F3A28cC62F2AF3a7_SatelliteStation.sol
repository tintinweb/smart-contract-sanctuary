/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

//    _____ ______   _________  _____ ______          
//   |\   _ \  _   \|\___   ___\\   _ \  _   \        
//   \ \  \\\__\ \  \|___ \  \_\ \  \\\__\ \  \       
//    \ \  \\|__| \  \   \ \  \ \ \  \\|__| \  \      
//     \ \  \    \ \  \   \ \  \ \ \  \    \ \  \     
//      \ \__\    \ \__\   \ \__\ \ \__\    \ \__\    
//       \|__|     \|__|    \|__|  \|__|     \|__|
//  
//    ________  ________  _________  _______   ___       ___       ___  _________  _______      
//   |\   ____\|\   __  \|\___   ___\\  ___ \ |\  \     |\  \     |\  \|\___   ___\\  ___ \     
//   \ \  \___|\ \  \|\  \|___ \  \_\ \   __/|\ \  \    \ \  \    \ \  \|___ \  \_\ \   __/|    
//    \ \_____  \ \   __  \   \ \  \ \ \  \_|/_\ \  \    \ \  \    \ \  \   \ \  \ \ \  \_|/__  
//     \|____|\  \ \  \ \  \   \ \  \ \ \  \_|\ \ \  \____\ \  \____\ \  \   \ \  \ \ \  \_|\ \ 
//       ____\_\  \ \__\ \__\   \ \__\ \ \_______\ \_______\ \_______\ \__\   \ \__\ \ \_______\
//      |\_________\|__|\|__|    \|__|  \|_______|\|_______|\|_______|\|__|    \|__|  \|_______|
//      \|_________|                                                                            
//                                                                                             
//    ________  _________  ________  _________  ___  ________  ________      
//   |\   ____\|\___   ___\\   __  \|\___   ___\\  \|\   __  \|\   ___  \    
//   \ \  \___|\|___ \  \_\ \  \|\  \|___ \  \_\ \  \ \  \|\  \ \  \\ \  \   
//    \ \_____  \   \ \  \ \ \   __  \   \ \  \ \ \  \ \  \\\  \ \  \\ \  \  
//     \|____|\  \   \ \  \ \ \  \ \  \   \ \  \ \ \  \ \  \\\  \ \  \\ \  \ 
//       ____\_\  \   \ \__\ \ \__\ \__\   \ \__\ \ \__\ \_______\ \__\\ \__\
//      |\_________\   \|__|  \|__|\|__|    \|__|  \|__|\|_______|\|__| \|__|
//      \|_________|                                                         
//
//
//
//                /#######*                                                 
//             ##################,                                          
//           .########################                                      
//          ,,############################                %%%%%%            
//         ,,,###############################,          .%%%%%%%%,          
//        ,,,,,#################################*       /%%%%%%%%           
//       .,,,,,/###################################,  %%%%%,//.             
//       ,,,.,,,/###################################%%%%%                   
//       ,,,,,,,,,###############################%%%%%##*                   
//       ,,,,,,,,,,########################%%%%%%%%########                 
//       ,,,,,,,,,,,,################%%%%%%%%%%%%%###########               
//       ,,,,,,,,,,,,,(#######%%%%%%%%%%#%%%%%%%%##############             
//       .,,,,,,,,,,,,,,#%%%%%%%%######%%%%%%%%%################(           
//        *,,,,,,,,,,,,,,,##########%%%%%##%%%%###################.         
//         ,,,,,,,,,,,,,,,,,/#####%%%%%###%%%%######################        
//          ,,,,,,,,.,,,,,,,.,,%%%%%#####%%%%########################       
//           *,,,,,,,,,,,,,,,,,,,#######%%%%##########################      
//            ,,,,,,,,,,,,,,,,,,,,,,###%%%%############################     
//              *,,,,,,,,,,,,,,,,,,,,,,#%%##############################    
//                *,,,,,,,,,.,,,,,,,,,,,,,(#############################.   
//                  **,,,,,,,,,,,,,,,,,,,,,,,,##########################*   
//                 .*****,,,,,,,,,,,,,,,,,,,,,,,,,######################    
//                 **********,,,,,,,,,,,,,,,,,,,,,,,,,,(##############,     
//                 .**********,***,,,,,,,,,,.,,,,,,,,,,,,,,,,,,,***         
//                    ******        ,******,,,,,,,,,,,,,******.             
//                    ,,,,,,                                                
//                    ,,,,,,                                                
//                 ************                                             
//                 ************                                             
//                 ************                                             
//                 ************                                             
//                 ************                                             
//              ,,,,,,,,,,,,,,,,,,                                          
//             ,,,,,,,,,,,,,,,,,,,,                                         
//            .,,,,,,,,,,,,,,,,,,,,.                                        
//            ,,,,,,,,,,,,,,.,,,,,,,                                        
//         ,,************************,,                                     
//        ******************************                                    
//        ,****************************.  

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

abstract contract SatelliteReceiver {
    // DO NOT CHANGE THIS!
    address public satelliteStationAddress;
    uint256 public SSTokensMinted = 0;

    // YOU NEED TO CONFIGURE THIS!
    address public SSTokenReceiver;
    address public SSTokenAddress;
    uint256 public SSTokensPerMint;
    uint256 public SSTokensAvailable;

    function _satelliteMint(uint256 amount_) internal {
        require(msg.sender == satelliteStationAddress, "_satelliteMint: msg.sender is not Satellite Station!");
        require(SSTokensAvailable >= SSTokensMinted + amount_, "_satelliteMint: amount_ requested over maximum avaialble tokens!");

        SSTokensMinted += amount_;
    }
}

interface iSatelliteReceiver {
    function satelliteMint(uint256 amount_) external;
    function SSTokenReceiver() external view returns (address);
    function SSTokenAddress() external view returns (address);
    function SSTokensPerMint() external view returns (uint256);
}

interface iMES {
    // View Functions
    function balanceOf(address address_) external view returns (uint256);
    function pendingRewards(address address_) external view returns (uint256); 
    function getStorageClaimableTokens(address address_) external view returns (uint256);
    function getPendingClaimableTokens(address address_) external view returns (uint256);
    function getTotalClaimableTokens(address address_) external view returns (uint256);
    // Administration
    function setYieldRate(address address_, uint256 yieldRate_) external;
    function addYieldRate(address address_, uint256 yieldRateAdd_) external;
    function subYieldRate(address address_, uint256 yieldRateSub_) external;
    // Updating
    function updateReward(address address_) external;
    // Credits System
    function deductCredits(address address_, uint256 amount_) external;
    function addCredits(address address_, uint256 amount_) external;
    // Burn
    function burn(address from, uint256 amount_) external;
}

// Open0x Ownable (by 0xInuarashi)
abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed oldOwner_, address indexed newOwner_);
    constructor() { owner = msg.sender; }
    modifier onlyOwner {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function _transferOwnership(address newOwner_) internal virtual {
        address _oldOwner = owner;
        owner = newOwner_;
        emit OwnershipTransferred(_oldOwner, newOwner_);    
    }
    function transferOwnership(address newOwner_) public virtual onlyOwner {
        require(newOwner_ != address(0x0), "Ownable: new owner is the zero address!");
        _transferOwnership(newOwner_);
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x0));
    }
}

contract SatelliteStation is Ownable {
    /* 
    MTM Sattelite Station

    An open interface with NFT projects to be able to mint
    from contracts through the satelliteMint function.

    Natively supports $MES and can be adapted to support other
    ERC20 tokens in the future as well.
    */

    // Initialize MES contract
    address public MESAddress = 0x984b6968132DA160122ddfddcc4461C995741513;
    iMES public MES = iMES(0x984b6968132DA160122ddfddcc4461C995741513);

    // Contract Variables
    address internal burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 internal globalModulus = 10 ** 14;

    // Structs
    struct SatelliteSettings {
        address tokenAddress_;
        uint40 tokensPerMint_;
        uint16 amountForMint_;
        uint16 amountPerAddress_;
        uint16 amountMinted_;
    }

    struct TransferForMintSettings {
        address tokenAddress_;
        uint40 tokensPerMint_;
        uint16 amountForMint_;
        uint16 amountPerAddress_;
        uint16 amountMinted_;
        address receiverAddress_;
    }

    struct BurnWLSettings {
        address tokenAddress_;
        uint40 tokensPerWL_;
        uint16 amountForWL_;
        uint16 amountAllocated_;
    }

    // Mappings (Satellite Mint)
    mapping(address => SatelliteSettings) public contractToSatelliteSettings;
    mapping(address => mapping(address => uint16)) public addressToSatelliteMinted;

    // Mappings (Transfer For Mint)
    mapping(address => TransferForMintSettings) public contractToTransferForMintSettings;
    mapping(address => mapping(address => uint16)) public addressToTransferForMintAmount;
    
    // Mappings (Satellite Burn for WL)
    mapping(string => BurnWLSettings) public projectToBurnWLSettings;
    mapping(string => mapping(address => bool)) public projectToWL;

    // Events
    event SatelliteMint(address minter_, address indexed contractAddress_, address tokenAddress_, uint256 tokensPerMint_, uint256 amount_, uint256 tokensDeducted_, bool useCredits_);
    event SatelliteTransferForMint(address minter_, address indexed contractAddress_, address tokenAddress_, uint256 tokensPerMint_, uint16 amountMinted_, address receiverAddress_);
    event SatelliteBurnForWL(address burner_, string indexed projectName_, uint256 amount_);


    function addSatelliteSetting(address contractAddress_, address tokenAddress_, uint40 tokensPerMint_, uint16 amountForMint_, uint16 amountPerAddress_) external onlyOwner {
        SatelliteSettings memory _SatelliteSettings = SatelliteSettings(
            tokenAddress_, 
            tokensPerMint_, 
            amountForMint_, 
            amountPerAddress_,
            0
        );
        contractToSatelliteSettings[contractAddress_] = _SatelliteSettings; 
    }

    function addTransferForMintSetting(address contractAddress_, address tokenAddress_, uint40 tokensPerMint_, uint16 amountForMint_, uint16 amountPerAddress_, address receiverAddress_) external onlyOwner {
        TransferForMintSettings memory _TransferForMintSettings = TransferForMintSettings(
            tokenAddress_,
            tokensPerMint_,
            amountForMint_,
            amountPerAddress_,
            0,
            receiverAddress_
        );
        contractToTransferForMintSettings[contractAddress_] = _TransferForMintSettings;
    }

    function addBurnWLSetting(string memory projectName_, address tokenAddress_, uint40 tokensPerWL_, uint16 amountForWL_) external onlyOwner {
        BurnWLSettings memory _BurnWLSettings = BurnWLSettings(
            tokenAddress_, 
            tokensPerWL_, 
            amountForWL_, 
            0
        );
        projectToBurnWLSettings[projectName_] = _BurnWLSettings; 
    }

    // Satellite Minting System
    function satelliteMint(address contractAddress_, address tokenAddress_, uint256 amount_, bool useCredits_) external {
        SatelliteSettings memory _SatelliteSettings = contractToSatelliteSettings[contractAddress_];
        address _SSTokenAddress = iSatelliteReceiver(contractAddress_).SSTokenAddress();
        address _SSTokenReceiver = iSatelliteReceiver(contractAddress_).SSTokenReceiver();
        uint256 _SSTokensPerMint = iSatelliteReceiver(contractAddress_).SSTokensPerMint();
        uint256 _tokensToDeduct = _SSTokensPerMint * amount_;

        require(_SatelliteSettings.tokenAddress_ != address(0x0),
            "satelliteMint: This contract is not in the Satellite Station program!");
        require(_SSTokenAddress == tokenAddress_,
            "satelliteMint: Token Address to Receiver mismatch!");
        require(_SatelliteSettings.amountForMint_ >= _SatelliteSettings.amountMinted_ + amount_,
            "satelliteMint: Amount requested to mint exceeds set remaining!");
        require(_SatelliteSettings.amountPerAddress_ >= addressToSatelliteMinted[contractAddress_][msg.sender] + amount_,
            "satelliteMint: Amount for mint exceeds limit per address!");
        require(_SSTokensPerMint == (uint256(_SatelliteSettings.tokensPerMint_) * globalModulus),
            "satelliteMint: Token cost per mint mismatch with receiver!");

        // $MES Credit System and ERC20 Transfer
        if (tokenAddress_ == MESAddress && useCredits_) {
            // Update Reward First Flow
            require(_tokensToDeduct <= MES.getTotalClaimableTokens(msg.sender), "Not enough MES Credits to do action!");
            if (_tokensToDeduct >= MES.getStorageClaimableTokens(msg.sender)) { MES.updateReward(msg.sender); }
            // Credit Balance Flow
            MES.deductCredits(msg.sender, _tokensToDeduct);
            MES.addCredits(_SSTokenReceiver, _tokensToDeduct);
        } else {
            require(_tokensToDeduct <= IERC20(tokenAddress_).balanceOf(msg.sender), "Not enough ERC20 to do action!");
            IERC20(tokenAddress_).transferFrom(msg.sender, _SSTokenReceiver, _tokensToDeduct);
        }

        addressToSatelliteMinted[contractAddress_][msg.sender] += uint16(amount_);
        contractToSatelliteSettings[contractAddress_].amountMinted_ += uint16(amount_);

        // The satelliteMint function is called after all the necessary checks.
        iSatelliteReceiver(contractAddress_).satelliteMint(amount_);

        emit SatelliteMint(msg.sender, contractAddress_, _SSTokenAddress, _SSTokensPerMint, amount_, _tokensToDeduct, useCredits_);
    }

    // Satellite Transfer for Mint System
    function satelliteTransferForMint(address contractAddress_, uint256 amount_, bool useCredits_) external {
        TransferForMintSettings memory _TransferForMintSettings = contractToTransferForMintSettings[contractAddress_]; 
        address _tokenAddress = _TransferForMintSettings.tokenAddress_;
        uint256 _tokensToDeduct = (uint256(_TransferForMintSettings.tokensPerMint_) * globalModulus) * amount_;
        address _receiverAddress = _TransferForMintSettings.receiverAddress_;

        require(_TransferForMintSettings.tokenAddress_ != address(0x0), 
            "satelliteTransferForMint: This contract is not in the Satellite Station program!");
        require(_TransferForMintSettings.amountForMint_ >= _TransferForMintSettings.amountMinted_ + amount_,
            "satelliteTransferForMint: No more mints available!");
        require(_TransferForMintSettings.amountPerAddress_ >= addressToTransferForMintAmount[contractAddress_][msg.sender] + amount_, 
            "satelliteTransferForMint: Amount exceeds allowed mints per address!");
        
        // $MES Credit System and ERC20 Transfer
        if (_TransferForMintSettings.tokenAddress_ == MESAddress && useCredits_) {
            // Update Reward First Flow
            require(_tokensToDeduct <= MES.getTotalClaimableTokens(msg.sender), "Not enough MES Credits to do action!");
            if (_tokensToDeduct >= MES.getStorageClaimableTokens(msg.sender)) { MES.updateReward(msg.sender); }
            // Credit Balance Flow
            MES.deductCredits(msg.sender, _tokensToDeduct);
            MES.addCredits(_receiverAddress, _tokensToDeduct);
        } else {
            require(_tokensToDeduct <= IERC20(_tokenAddress).balanceOf(msg.sender), "Not enough ERC20 to do action!");
            IERC20(_tokenAddress).transferFrom(msg.sender, _receiverAddress, _tokensToDeduct);
        }

        addressToTransferForMintAmount[contractAddress_][msg.sender] += uint16(amount_);
        contractToTransferForMintSettings[contractAddress_].amountMinted_ += uint16(amount_);
        
        emit SatelliteTransferForMint(msg.sender, contractAddress_, _tokenAddress, _tokensToDeduct, contractToTransferForMintSettings[contractAddress_].amountMinted_, _receiverAddress);
    }

    // Satellite Burn for Whitelist System
    function satelliteBurnForWL(string memory projectName_, bool useCredits_) external {
        require(!projectToWL[projectName_][msg.sender], "satelliteBurnForWL: You are already whitelisted!");

        BurnWLSettings memory _BurnWLSettings = projectToBurnWLSettings[projectName_];
        
        address _tokenAddress = _BurnWLSettings.tokenAddress_;
        uint256 _tokensToDeduct = uint256(_BurnWLSettings.tokensPerWL_) * globalModulus;

        // $MES Credit System
        if (_tokenAddress == MESAddress && useCredits_) {
            // Update Reward First Flow
            require(_tokensToDeduct <= MES.getTotalClaimableTokens(msg.sender), "Not enough MES Credits to do action!");
            if (_tokensToDeduct >= MES.getStorageClaimableTokens(msg.sender)) { MES.updateReward(msg.sender); }
            // Deduct Credits Flow
            MES.deductCredits(msg.sender, _tokensToDeduct);
        } else {
            require(_tokensToDeduct <= IERC20(_tokenAddress).balanceOf(msg.sender), "Not enough ERC20 to do action!");
            IERC20(_tokenAddress).transferFrom(msg.sender, burnAddress, _tokensToDeduct);
        }
        
        // add them to the WL!
        projectToWL[projectName_][msg.sender] = true;
        emit SatelliteBurnForWL(msg.sender, projectName_, _tokensToDeduct);
    }
}