// SPDX-License-Identifier: No License (None)
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IBSCswapRouter02.sol";


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IReimbursement {
    function getLicenseeFee(address licenseeVault, address projectContract) external view returns(uint256); // return fee percentage with 2 decimals
    function getVaultOwner(address vault) external view returns(address);
    // returns address of fee receiver or address(0) if licensee can't receive the fee (fee should be returns to user)
    function requestReimbursement(address user, uint256 feeAmount, address licenseeVault) external returns(address);
}

contract UniswapIntermediateAgent is Ownable{
    using TransferHelper for address;
    
    IReimbursement public reimbursementContract;
    address public companyVault;    // the vault address of our company registered in reimbursement contract
    mapping(address => uint256) public routerInterface; // type on router interface: 0 = uniswap, 1 = BSCswap

    constructor(address _reimbursementContract) {      
        reimbursementContract = IReimbursement(_reimbursementContract);
    }
    
    function setReimbursement(address _reimbursement)external onlyOwner{
        require(_reimbursement != address(0), "Invalid address");
        reimbursementContract = IReimbursement(_reimbursement);
    }

    // set address of company vault (ID) in reimbursement contract
    function setCompanyVault(address _vault) external onlyOwner{
        companyVault = _vault;
    }

    // set type of interface of selected router.
    // _type: 0 = uniswap, 1 = BSCswap
    function setRouterInterface(address _router, uint256 _type) external onlyOwner {
        routerInterface[_router] = _type;
    }

    event Swap(
        address indexed user,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    );
        
    function getFee(
        address fromToken,  // address(0) means native coin (ETH, BNB)
        uint256 amountIn, 
        address licensee,
        address uniV2Router   // Uniswap-compatible router address
    ) 
    external
    view
    returns(uint256) 
    {
        uint256 feeLicensee;
        uint256 feeBswap;
        address[] memory tempPath = new address[](2);
        uint256 licenseeFeeRate = reimbursementContract.getLicenseeFee(licensee, address(this));
        uint256 feeRate = reimbursementContract.getLicenseeFee(companyVault, address(this));
        if (routerInterface[uniV2Router] == 1) {
            tempPath[1] = IBSCswapRouter02(uniV2Router).WBNB();
        } else {
            tempPath[1] = IUniswapV2Router02(uniV2Router).WETH();
        }
        if(fromToken == address(0) || fromToken == tempPath[1]) {
            feeLicensee = amountIn * licenseeFeeRate / 10000;
            feeBswap = amountIn * feeRate / 10000;
        }
        else {
                tempPath[0] = fromToken;
                uint256[] memory totalFeeAmt = IUniswapV2Router02(uniV2Router).getAmountsOut(amountIn, tempPath); 
                feeBswap = totalFeeAmt[1] * feeRate / 10000;
                
                if(licenseeFeeRate>0){
                    feeLicensee = totalFeeAmt[1] * licenseeFeeRate / 10000;
                }
        }
        return feeBswap + feeLicensee;
    }

    function swap(
        address payable licensee,
        uint256 amountIn,                                                       // amount of token to swap
        uint256 amountOut,                                                      // minimum amount of token to receive
        address[] memory path,                                                  // address(0) means native coin (ETH, BNB)
        uint256 deadline,
        uint256 swapType,                                                        // allow to choose the correct swap function: 
                                                                                // 0 - swap Exact Tokens For Token; 
                                                                                // 1 - swap Tokens For Exact Token SupportingFeeOnTransferTokens;
                                                                                // 2 - swap Tokens For Exact Token; 
        address uniV2Router   // Uniswap-compatible router address
    ) 
        external
        payable
        returns (uint256[] memory amounts) 
    {
        if (routerInterface[uniV2Router] == 1) {
            return swapBSC(licensee, amountIn, amountOut, path, deadline, swapType, IBSCswapRouter02(uniV2Router));
        } else {
            return swapUni(licensee, amountIn, amountOut, path, deadline, swapType, IUniswapV2Router02(uniV2Router));
        }
    }

    function swapUni(
        address payable licensee,
        uint256 amountIn,                                                       // amount of token to swap
        uint256 amountOut,                                                      // minimum amount of token to receive
        address[] memory path,                                                  // address(0) means native coin (ETH, BNB)
        uint256 deadline,
        uint256 swapType,                                                        // allow to choose the correct swap function: 
                                                                                // 0 - swap Exact Tokens For Token; 
                                                                                // 1 - swap Tokens For Exact Token SupportingFeeOnTransferTokens;
                                                                                // 2 - swap Tokens For Exact Token; 
        IUniswapV2Router02 uniV2Router   // Uniswap-compatible router address
    ) 
        internal
        returns (uint256[] memory amounts) 
    {
        bool toETH;
        bool fromETH;
        uint256 totalGas = gasleft();
        uint256 totalFee;
        totalFee = msg.value;                                                   // assume that all coins that user send is a fee
    
        if (path[0] == address(0)) {                                             // swap from native coin (ETH, BNB)
            totalFee = totalFee - amountIn;                                   // separate fee from swapping value
            path[0] = uniV2Router.WETH();
            fromETH = true;
        } else {                                                                 // transfer token from user and approve to Router
            path[0].safeTransferFrom(msg.sender, address(this), amountIn);
            path[0].safeApprove(address(uniV2Router), amountIn);        
        }
    
        if (path[path.length-1] == address(0)) {                                 // swap to native coin (ETH, BNB)
            path[path.length-1] = uniV2Router.WETH();
            toETH = true;
        }
        
        require (!fromETH || !toETH, "Swapping from ETH to ETH is forbidden");

        totalFee =  CalculateTokenAmounts(                        // function to find bswap and mint licensee token
             uniV2Router.WETH(),
             amountIn, 
             path, 
             licensee,
             totalFee,
             uniV2Router
        );
        
        if (swapType == 0) {                    
            if (fromETH) {
                amounts = uniV2Router.swapExactETHForTokens{value: amountIn}(
                    0,
                    path,
                    msg.sender,
                    deadline
                );
            } else if (toETH) {
                amounts = uniV2Router.swapExactTokensForETH(
                    amountIn,
                    amountOut,
                    path,
                    payable(msg.sender),
                    deadline
                );            
            } else {
                amounts = uniV2Router.swapExactTokensForTokens(
                    amountIn,
                    amountOut,
                    path,
                    msg.sender,
                    deadline
                );
            }
        } else if (swapType == 1) {
            if (fromETH) {
                uniV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountIn}(
                    0,
                    path,
                    msg.sender,
                    deadline
                );
            } else if (toETH) {
                uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    amountIn,
                    amountOut,
                    path,
                    payable(msg.sender),
                    deadline
                );            
            } else {
                uniV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    amountIn,
                    amountOut,
                    path,
                    msg.sender,
                    deadline
                );
            }
        } else if (swapType == 2) {
            if (fromETH) {
                amounts = uniV2Router.swapETHForExactTokens{value: amountIn}(
                    amountOut,
                    path,
                    msg.sender,
                    deadline
                );
                
                if(amountIn - amounts[0] > 0){
                    payable(msg.sender).transfer(amountIn - amounts[0]);
                }

            } else if (toETH) {
                amounts = uniV2Router.swapTokensForExactETH(
                    amountOut,
                    amountIn,
                    path,
                    payable(msg.sender),
                    deadline
                );
                
                if(amountIn - amounts[0] > 0){
                    path[0].safeTransfer(msg.sender, (amountIn - amounts[0]));
                }
            } else {
                amounts = uniV2Router.swapTokensForExactTokens(
                    amountOut,
                    amountIn,
                    path,
                    msg.sender,
                    deadline
                );
                
                if(amountIn - amounts[0] > 0){
                    path[0].safeTransfer(msg.sender, (amountIn - amounts[0]));
                }
            }
        }else { 
            revert("Wrong type");
        }
    
        totalGas = (totalGas - gasleft()) * tx.gasprice;
        // request reimbursement for user
        reimbursementContract.requestReimbursement(msg.sender, totalFee + totalGas, companyVault);
        emit Swap(msg.sender, path[0], path[1], amountIn, amounts[1]);      // emit swap event
    }
    
    function swapBSC(
        address payable licensee,
        uint256 amountIn,                                                       // amount of token to swap
        uint256 amountOut,                                                      // minimum amount of token to receive
        address[] memory path,                                                  // address(0) means native coin (ETH, BNB)
        uint256 deadline,
        uint256 swapType,                                                        // allow to choose the correct swap function: 
                                                                                // 0 - swap Exact Tokens For Token; 
                                                                                // 1 - swap Tokens For Exact Token SupportingFeeOnTransferTokens;
                                                                                // 2 - swap Tokens For Exact Token; 
        IBSCswapRouter02 uniV2Router   // Uniswap-compatible router address
    ) 
        internal
        returns (uint256[] memory amounts) 
    {
        bool toBNB;
        bool fromBNB;
        uint256 totalGas = gasleft();
        uint256 totalFee;
        totalFee = msg.value;                                                   // assume that all coins that user send is a fee
    
        if (path[0] == address(0)) {                                             // swap from native coin (ETH, BNB)
            totalFee = totalFee - amountIn;                                   // separate fee from swapping value
            path[0] = uniV2Router.WBNB();
            fromBNB = true;
        } else {                                                                 // transfer token from user and approve to Router
            path[0].safeTransferFrom(msg.sender, address(this), amountIn);
            path[0].safeApprove(address(uniV2Router), amountIn);        
        }
    
        if (path[path.length-1] == address(0)) {                                 // swap to native coin (ETH, BNB)
            path[path.length-1] = uniV2Router.WBNB();
            toBNB = true;
        }
        
        require (!fromBNB || !toBNB, "Swapping from BNB to BNB is forbidden");

        totalFee =  CalculateTokenAmounts(                        // function to find bswap and mint licensee token
             uniV2Router.WBNB(),
             amountIn, 
             path, 
             licensee,
             totalFee,
             IUniswapV2Router02(address(uniV2Router))
        );
        
        if (swapType == 0) {                    
            if (fromBNB) {
                amounts = uniV2Router.swapExactBNBForTokens{value: amountIn}(
                    0,
                    path,
                    msg.sender,
                    deadline
                );
            } else if (toBNB) {
                amounts = uniV2Router.swapExactTokensForBNB(
                    amountIn,
                    amountOut,
                    path,
                    payable(msg.sender),
                    deadline
                );            
            } else {
                amounts = uniV2Router.swapExactTokensForTokens(
                    amountIn,
                    amountOut,
                    path,
                    msg.sender,
                    deadline
                );
            }
        } else if (swapType == 1) {
            if (fromBNB) {
                uniV2Router.swapExactBNBForTokensSupportingFeeOnTransferTokens{value: amountIn}(
                    0,
                    path,
                    msg.sender,
                    deadline
                );
            } else if (toBNB) {
                uniV2Router.swapExactTokensForBNBSupportingFeeOnTransferTokens(
                    amountIn,
                    amountOut,
                    path,
                    payable(msg.sender),
                    deadline
                );            
            } else {
                uniV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    amountIn,
                    amountOut,
                    path,
                    msg.sender,
                    deadline
                );
            }
        } else if (swapType == 2) {
            if (fromBNB) {
                amounts = uniV2Router.swapBNBForExactTokens{value: amountIn}(
                    amountOut,
                    path,
                    msg.sender,
                    deadline
                );
                
                if(amountIn - amounts[0] > 0){
                    payable(msg.sender).transfer(amountIn - amounts[0]);
                }

            } else if (toBNB) {
                amounts = uniV2Router.swapTokensForExactBNB(
                    amountOut,
                    amountIn,
                    path,
                    payable(msg.sender),
                    deadline
                );
                
                if(amountIn - amounts[0] > 0){
                    path[0].safeTransfer(msg.sender, (amountIn - amounts[0]));
                }
            } else {
                amounts = uniV2Router.swapTokensForExactTokens(
                    amountOut,
                    amountIn,
                    path,
                    msg.sender,
                    deadline
                );
                
                if(amountIn - amounts[0] > 0){
                    path[0].safeTransfer(msg.sender, (amountIn - amounts[0]));
                }
            }
        }else { 
            revert("Wrong type");
        }
    
        totalGas = (totalGas - gasleft()) * tx.gasprice;
        // request reimbursement for user
        reimbursementContract.requestReimbursement(msg.sender, totalFee + totalGas, companyVault);
        emit Swap(msg.sender, path[0], path[1], amountIn, amounts[1]);      // emit swap event
    }

    function CalculateTokenAmounts(
        address WETH,
        uint256 amountIn, 
        address[] memory path, 
        address payable licensee,
        uint256 totalFee,
        IUniswapV2Router02 uniV2Router
    ) 
        internal 
        returns(uint256)
        {
                
        uint256 feeLicensee;
        uint256 feeBswap;
        address[] memory tempPath = new address[](2);
        uint256 licenseeFeeRate = reimbursementContract.getLicenseeFee(licensee, address(this));
        uint256 feeRate = reimbursementContract.getLicenseeFee(companyVault, address(this));
        
        if(WETH == path[0]) { // swapping from native coin
            feeLicensee = amountIn * licenseeFeeRate / 10000;
            feeBswap = amountIn * feeRate / 10000;
        }
        else {
                tempPath[0] = path[0];
                tempPath[1] = WETH;
                uint256[] memory totalFeeAmt = uniV2Router.getAmountsOut(amountIn, tempPath); 
                feeBswap = totalFeeAmt[1] * feeRate / 10000;
                
                if(licenseeFeeRate > 0){
                    feeLicensee = totalFeeAmt[1] * licenseeFeeRate / 10000;
                }
        }
    
        uint256 refundFee;
        if(feeLicensee != 0){
            address licenseeFeeTo = reimbursementContract.requestReimbursement(msg.sender, feeLicensee, licensee);
            if (licenseeFeeTo == address(0)) {
                refundFee = feeLicensee;    // refund to user
            } else {
                payable(licenseeFeeTo).transfer(feeLicensee);  // transfer to fee receiver
            }                                            
        }

        require (refundFee + totalFee >= feeLicensee + feeBswap, "Insufficient fee");
        refundFee = (refundFee + totalFee) - (feeLicensee + feeBswap);
        if (refundFee > (20000 * tx.gasprice))                                              // avoid spending more gas on transfer than the amount to refund
            payable(msg.sender).transfer(refundFee);                                                 
        else
            feeBswap += refundFee;                                                          // add small amount to company fee
            
        payable(owner()).transfer(feeBswap);
        
        return feeBswap;
    }
    
    receive() external payable {}
}