/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

/*
$$\      $$\ $$\                                    $$\ $$\                                                   
$$ | $\  $$ |\__|                                   $$ |\__|                                                  
$$ |$$$\ $$ |$$\ $$$$$$$$\ $$$$$$\   $$$$$$\   $$$$$$$ |$$\ $$\   $$\ $$$$$$\$$$$\                            
$$ $$ $$\$$ |$$ |\____$$  |\____$$\ $$  __$$\ $$  __$$ |$$ |$$ |  $$ |$$  _$$  _$$\                           
$$$$  _$$$$ |$$ |  $$$$ _/ $$$$$$$ |$$ |  \__|$$ /  $$ |$$ |$$ |  $$ |$$ / $$ / $$ |                          
$$$  / \$$$ |$$ | $$  _/  $$  __$$ |$$ |      $$ |  $$ |$$ |$$ |  $$ |$$ | $$ | $$ |                          
$$  /   \$$ |$$ |$$$$$$$$\\$$$$$$$ |$$ |      \$$$$$$$ |$$ |\$$$$$$  |$$ | $$ | $$ |                          
\__/     \__|\__|\________|\_______|\__|       \_______|\__| \______/ \__| \__| \__|                          
                                                                                                              
                                                                                                              
                                                                                                              
                         $$$$$$\   $$$$$$\  $$\      $$\ $$$$$$$$\                                            
                        $$  __$$\ $$  __$$\ $$$\    $$$ |$$  _____|                                           
                        $$ /  \__|$$ /  $$ |$$$$\  $$$$ |$$ |                                                 
                        $$ |$$$$\ $$$$$$$$ |$$\$$\$$ $$ |$$$$$\                                               
                        $$ |\_$$ |$$  __$$ |$$ \$$$  $$ |$$  __|                                              
                        $$ |  $$ |$$ |  $$ |$$ |\$  /$$ |$$ |                                                 
                        \$$$$$$  |$$ |  $$ |$$ | \_/ $$ |$$$$$$$$\                                            
                         \______/ \__|  \__|\__|     \__|\________|                                           
                                                                                                              
                                                                                                              
                                                                                                              
                                          $$\    $$\ $$$$$$$$\  $$$$$$\ $$$$$$$$\ $$$$$$\ $$\   $$\  $$$$$$\  
                                          $$ |   $$ |$$  _____|$$  __$$\\__$$  __|\_$$  _|$$$\  $$ |$$  __$$\ 
                                          $$ |   $$ |$$ |      $$ /  \__|  $$ |     $$ |  $$$$\ $$ |$$ /  \__|
                                          \$$\  $$  |$$$$$\    \$$$$$$\    $$ |     $$ |  $$ $$\$$ |$$ |$$$$\ 
                                           \$$\$$  / $$  __|    \____$$\   $$ |     $$ |  $$ \$$$$ |$$ |\_$$ |
                                            \$$$  /  $$ |      $$\   $$ |  $$ |     $$ |  $$ |\$$$ |$$ |  $$ |
                                             \$  /   $$$$$$$$\ \$$$$$$  |  $$ |   $$$$$$\ $$ | \$$ |\$$$$$$  |
                                              \_/    \________| \______/   \__|   \______|\__|  \__| \______/ 
                                                                                                              
                                                                                                              
                                                                                                              
*/

//SPDX-License-Identifier: GPLv3

pragma solidity >=0.7.0;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract WizardiumContracts is Ownable {
    mapping(address => bool) private wizContracts;

    function addToWizContracts(address _nContract) public onlyOwner {
        wizContracts[_nContract] = true;
    }

    function removeWizContracts(address _contract) public onlyOwner {
        wizContracts[_contract] = false;
    }

    modifier isWizContract() {
        require(wizContracts[_msgSender()], "Only Wizaridium contracts are able to call");
        _;
    }
}
interface WizzERC20 {
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);    
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract FarmVesting is WizardiumContracts {
    struct Vestment {
        uint256 totalAmount;
        uint256[] timestamps;
        uint256[] percentages;
        bool active;
    }

    mapping(address => Vestment[]) farmers;

    address WIZZY = 0x9E327B55D5791bd1b08222F7886d7a82EB11aCEE;
    uint256 totalVestments;
    uint256 priceBasis = 1 ether;

    function addVestment(address farmer, uint256 _totalAmount, uint256[] memory _timestamps, uint256[] memory _percentages) public isWizContract {
        farmers[farmer].push(Vestment(_totalAmount, _timestamps, _percentages, true));
        totalVestments+= _totalAmount;
    }

    function policyVestmentAdd(address farmer, uint256 _totalAmount, uint256[] memory _timestamps, uint256[] memory _percentages) external onlyOwner {

        farmers[farmer].push(Vestment(_totalAmount, _timestamps, _percentages, true));
        totalVestments+= _totalAmount;
    }

    function sendPayment(address farmer, uint256 total) internal returns(bool) {
        total = total*priceBasis;
        require(total > 0, "Cannot pay 0!");
        require(WizzERC20(WIZZY).balanceOf(address(this)) > total, "Not enough money to support farming");
        require(WizzERC20(WIZZY).transfer(farmer, total), "Unable to transfer");
        return true;
    }

    function ownerWithdraw(uint256 amount) external onlyOwner {
        require(WizzERC20(WIZZY).balanceOf(address(this)) > totalVestments+amount, "Unable to withdraw more than combined vestments");
        sendPayment(msg.sender, amount);
    }

    function ownerCheck() external onlyOwner view returns(uint256) {

        return(totalVestments);
    }

    function checkFarmingReturns(address farmer) public view returns(uint256 total, uint256 totalWithdrawable, uint256 nextClaimTime){
        Vestment[] memory farmerVestments = farmers[farmer];
        uint256 currentTS = block.timestamp;
        nextClaimTime = block.timestamp+1000;
        for(uint256 i=0; i<farmerVestments.length; i++){
            uint256 totalAmount = farmerVestments[i].totalAmount;
            uint256[] memory vestmentTS = farmerVestments[i].timestamps;
            for(uint256 j=0; j<vestmentTS.length;j++){
                if((vestmentTS[j] != 0)){
                    total += ((totalAmount*farmerVestments[i].percentages[j])/100);
                    if((vestmentTS[j] < currentTS)){
                        totalWithdrawable += ((totalAmount*farmerVestments[i].percentages[j])/100);
                    }
                    if(vestmentTS[j] < nextClaimTime && vestmentTS[j] > block.timestamp){
                        nextClaimTime = vestmentTS[j];
                    }
                }
            }
        }
        if(total == 0 || totalWithdrawable != 0){
            nextClaimTime = 0;
        }
    }

    function farmerWithdraw(address farmer) external isWizContract {
        _safeWithdraw(farmer);
    }

    function _safeWithdraw(address farmer) internal {
        Vestment[] storage farmerVestments = farmers[farmer];
        uint256 total = 0;
        uint256 currentTS = block.timestamp;
        for(uint256 i=0; i<farmerVestments.length; i++){
            uint256[] storage vestmentTS = farmerVestments[i].timestamps;
            uint256 totalAmount = farmerVestments[i].totalAmount;
            for(uint256 j=0; j<vestmentTS.length;j++){
                if((vestmentTS[j] < currentTS) && (vestmentTS[j] != 0)){
                    total += ((totalAmount*farmerVestments[i].percentages[j])/100);
                    vestmentTS[j] = 0;
                }
            }
        }
        require(sendPayment(farmer, total), "Unable to send payment");
        if(totalVestments > total){
            totalVestments -= total;
        }
    }
}