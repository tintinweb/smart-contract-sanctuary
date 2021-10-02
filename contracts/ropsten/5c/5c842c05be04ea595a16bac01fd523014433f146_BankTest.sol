/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

/*
SPDX-License-Identifier: UNLICENSED" for non-open-source code. Please see https://spdx.org for more information.
*/
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract BankTest {

    function getStakeInputData() public pure returns (string[3] memory data ) {
        data[0] = "USDT,BNB,MDX";
        data[1] = "12-31-2021,11-11-2021,01-01-2022";
        data[2] = "30,40,10";
    }

    function getUSDTRate() public pure returns (int){
        int a = 6;
        return a;
    }

    function getBNBRate() public pure returns (int){
        int a = 4;
        return a;
    }

    function getMDXRate() public pure returns (int){
        int a = 5;
        return a;
    }


    struct OutputData {
        uint nonce;
        uint eta;
        uint p;

    }

    OutputData[] public data;

    function getOutputData() public returns (OutputData[] memory){
        for (uint i = 1; i <= 20; i++) {
            OutputData memory newDati = OutputData({
            nonce : i,
            eta : block.timestamp - (1000000 * i),
            p : i * 5
            });
            data.push(newDati);
        }
        OutputData[] memory d = data;
        return d;
    }
    
    
    function getBalances() public pure returns (string[4] memory arr){
        arr[0] = "123.34";
        arr[1] = "1223.34";
        arr[2] = "1223.213";
        arr[3] = "231.213";

        return (arr);
    }
    
    
    function getRefData() public pure returns (string memory json){
         json = '[{"name":"SASH BAlANCE","num":"115.79","unit":"SASH Ⓘ"},{"name":"L1 SGM REQUIREMENT","num":"115.79/12","unit":"SGM Ⓘ"},{"name":"SGM BALANCE","num":"23.79","unit":"SGM Ⓘ"},{"name":"LOCKED SASH","num":"23.79","unit":"SASH Ⓘ"},{"name":"L2 SGM REQUIREMENT","num":"23.79/24.34","unit":"SGM Ⓘ"},{"name":"LOCKED SGM","num":"12.43","unit":"SGM Ⓘ"}]';
       
    }
    
    function getBondsDexColumns() public pure returns (string[5] memory columns){
        columns[0] = "SYMBOL";
        columns[1] = "ENDED IN";
        columns[2] = "PROGRESS";
        columns[3] = "PRICE";
        columns[4] = "FACE Value";
    }
    
    function getBondsDexData() public pure returns(string memory a){
        a = '{"symbol":"USD","endedIn":"124H21M","progress":"10","price":"2122.22","faceValue":"10%","icon":"","list":[{"nonce":"N°24","eta":"08-08-2021","progress":"40","inSASH":"21.21","inUSD":"$ 25.33"},{"nonce":"N°24","eta":"08-08-2021","progress":"40","inSASH":"21.21","inUSD":"$ 25.33"},{"nonce":"N°24","eta":"08-08-2021","progress":"40","inSASH":"21.21","inUSD":"$ 25.33"}]}';
        return a;
    }
    
    function getBondsDexErc20LoanData() public pure returns(string memory datas){
        datas = '[{"symbol":"NFT","balance":"54.34","Loan":675,"IR":"67%","DueDate":"2022-12-03","EndedIn":"124H/12M","list":[{"name":"Pledge Value Ⓘ","num":"435.41 ETH ( 313,4 USD)"},{"name":"Loan Ⓘ","num":"7675.41 ETH ( 313,4 USD)"},{"name":"Mortgage Rates Ⓘ","num":"12%"},{"name":"Repayment Ⓘ","num":"56.49 SASH（453.11USD）"},{"name":"Mortgage Rates Ⓘ","num":"78%"},{"name":"Due Date Ⓘ","num":"2022-04-04（120D/23H/32M）"},{"name":"APYⒾ","num":"142.32%"},{"name":"APYⒾ","num":"142.32%"}]},{"symbol":"ETH","balance":"24.34","Loan":234,"IR":"34%","DueDate":"2022-02-03","EndedIn":"124H/12M","list":[{"name":"Pledge Value Ⓘ","num":"24.41 ETH ( 313,4 USD)"},{"name":"Loan Ⓘ","num":"24.41 ETH ( 313,4 USD)"},{"name":"Mortgage Rates Ⓘ","num":"82%"},{"name":"Repayment Ⓘ","num":"235.49 SASH（453.11USD）"},{"name":"Mortgage Rates Ⓘ","num":"82%"},{"name":"Due Date Ⓘ","num":"2022-04-04（120D/23H/32M）"},{"name":"APYⒾ","num":"142.32%"},{"name":"APYⒾ","num":"142.32%"}]},{"symbol":"HT","balance":"8678.34","Loan":678,"IR":"89%","DueDate":"2024-02-03","EndedIn":"1212H/12M","list":[{"name":"Pledge Value Ⓘ","num":"7868.41 ETH ( 313,4 USD)"},{"name":"Loan Ⓘ","num":"78.41 ETH ( 313,4 USD)"},{"name":"Mortgage Rates Ⓘ","num":"56%"},{"name":"Repayment Ⓘ","num":"56464.49 SASH（453.11USD）"},{"name":"Mortgage Rates Ⓘ","num":"56%"},{"name":"Due Date Ⓘ","num":"2025-04-04（120D/23H/32M）"},{"name":"APYⒾ","num":"67.32%"}]},{"symbol":"MDX","balance":"345.34","Loan":768,"IR":"67%","DueDate":"2024-02-03","EndedIn":"565H/12M","list":[{"name":"Pledge Value Ⓘ","num":"7868.41 ETH ( 313,4 USD)"},{"name":"Loan Ⓘ","num":"78.41 ETH ( 313,4 USD)"},{"name":"Mortgage Rates Ⓘ","num":"56%"},{"name":"Repayment Ⓘ","num":"56464.49 SASH（453.11USD）"},{"name":"Mortgage Rates Ⓘ","num":"56%"},{"name":"Due Date Ⓘ","num":"2025-04-04（120D/23H/32M）"},{"name":"APYⒾ","num":"67.32%"}]},{"symbol":"BNB","balance":"6787.34","Loan":45645,"IR":"34%","DueDate":"2024-02-03","EndedIn":"565H/12M","list":[{"name":"Pledge Value Ⓘ","num":"7868.41 ETH ( 313,4 USD)"},{"name":"Loan Ⓘ","num":"78.41 ETH ( 313,4 USD)"},{"name":"Mortgage Rates Ⓘ","num":"56%"},{"name":"Repayment Ⓘ","num":"56464.49 SASH（453.11USD）"},{"name":"Mortgage Rates Ⓘ","num":"56%"},{"name":"Due Date Ⓘ","num":"2025-04-04（120D/23H/32M）"},{"name":"APYⒾ","num":"67.32%"}]}]';
        
    }
    
    function getBondsDexErc20LoanColumns() public pure returns(string[6] memory dataes){
        dataes[0]="SYMBOL";
        dataes[1]="BALANCE";
        dataes[2]="Loan";
        dataes[3]="IR";
        dataes[4]="Due Date";
        dataes[5]="ENDED in";
    }


    function getBondsDexNFTData() public pure returns(string memory data4){
        data4 = '[{"symbol":"NFT","Author":"CryptoPunk","Loan":675,"IR":"67%","DueDate":"2022-12-03","EndedIn":"124H/12M","list":[{"name":"Loan Ⓘ","num":"435.41 ETH ( 313,4 USD)","span":24},{"name":"Repayment Ⓘ","num":"7675.41 ETH ( 313,4 USD)","span":24},{"name":"Due Date Ⓘ","num":"12%","span":24},{"name":"APYⒾ","num":"123%","span":12}]},{"symbol":"NFT","Author":"CryptoPunk","Loan":234,"IR":"34%","DueDate":"2022-02-03","EndedIn":"124H/12M","list":[{"name":"Loan Ⓘ","num":"435.41 ETH ( 313,4 USD)","span":24},{"name":"Repayment Ⓘ","num":"7675.41 ETH ( 313,4 USD)","span":24},{"name":"Due Date Ⓘ","num":"12%","span":24},{"name":"APYⒾ","num":"123%","span":12}]},{"symbol":"NFT","Author":"CryptoPunk","Loan":678,"IR":"89%","DueDate":"2024-02-03","EndedIn":"1212H/12M","list":[{"name":"Loan Ⓘ","num":"435.41 ETH ( 313,4 USD)","span":24},{"name":"Repayment Ⓘ","num":"7675.41 ETH ( 313,4 USD)","span":24},{"name":"Due Date Ⓘ","num":"12%","span":24},{"name":"APYⒾ","num":"123%","span":12}]},{"symbol":"NFT","Author":"CryptoPunk","Loan":768,"IR":"67%","DueDate":"2024-02-03","EndedIn":"565H/12M","list":[{"name":"Loan Ⓘ","num":"435.41 ETH ( 313,4 USD)","span":24},{"name":"Repayment Ⓘ","num":"7675.41 ETH ( 313,4 USD)","span":24},{"name":"Due Date Ⓘ","num":"12%","span":24},{"name":"APYⒾ","num":"123%","span":12}]},{"symbol":"NFT","Author":"CryptoPunk","Loan":45645,"IR":"34%","DueDate":"2024-02-03","EndedIn":"565H/12M","list":[{"name":"Loan Ⓘ","num":"435.41 ETH ( 313,4 USD)","span":24},{"name":"Repayment Ⓘ","num":"7675.41 ETH ( 313,4 USD)","span":24},{"name":"Due Date Ⓘ","num":"12%","span":24},{"name":"APYⒾ","num":"123%","span":12}]}]';
      
    }
    
    
    function getBondsDexNFTColumns() public pure returns(string[6] memory data6){
        data6[0]="SYMBOL";
        data6[1]="Author";
        data6[2]="Loan";
        data6[3]="IR";
        data6[4]="Due Date";
        data6[5]="ENDED in";
    }
    
    
    struct bondItem {
        string types;
        string name;
        int progress;
        int amount;
    }
    
    bondItem[] public bondArr;
    
    function handleStaking(string memory types,string memory name,int progress,int amount) public {
        bondItem memory _bondItem;
        _bondItem.types = types;
        _bondItem.name = name;
        _bondItem.progress = progress;
        _bondItem.amount = amount;
        
        bondArr.push(_bondItem);
    } 
    
    function handleBuy(string memory types,string memory name,int progress,int amount) public {
        bondItem memory _bondItem;
        _bondItem.types = types;
        _bondItem.name = name;
        _bondItem.progress = progress;
        _bondItem.amount = amount;
        
        bondArr.push(_bondItem);
    } 
    function handleVote(address _address) public returns(string memory){
        string memory voteInfo;
        voteInfo = "Vote successful";
        return voteInfo;
    }
    
    
    function handleCliam(address _address) public returns(string memory){
        string memory aridropInfo = "You are not in the airdrop list";
        return aridropInfo;
    }
    
    function handleRef(string memory _info) public returns(string memory){
        return _info;
    }
}