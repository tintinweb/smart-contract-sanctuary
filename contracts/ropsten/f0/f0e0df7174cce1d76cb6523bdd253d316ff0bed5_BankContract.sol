/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract BankContract
{
    address payable owner;                                 // адрес владельца банка
    uint BankBalance;
    mapping(address => bool) stuff;                        // словарь работников банка
    mapping(address => string) resumes;                    // словарь резюме(для тех, кто хочет стать соотрудником)
    mapping(address => string) creditApplications;         // словарь с людьми, ожидающими выдачи кредита
    int[][] tariffes;                                      // Список кредитных тарифов

    mapping(address => mapping(string => int)) CreditsInfo; // Хранит в себе всю информацию про взявших кредит
                                                            // "TookCredit" - взят ли кредит
                                                            // "CreditSummary" - Сумма, оставшаяся к выплате
                                                            // "MonthPayment" - ежемесячная выплата по кредиту
                                                            // "Percent" - начисляемый банком ежемесячный процент по кредиту

    modifier StuffOnly()    // модификатор для соотрудников банка
    {
        require(stuff[msg.sender]);
        _;
    }

    modifier OwnerOnly()    // модификатор владельца банка
    {
        require(msg.sender == owner);
        _;
    }

    receive() external payable {                                 // Получение месячной платы
        require(CreditsInfo[msg.sender]["TookCredit"] == 1);
        int Received = int(address(this).balance - BankBalance);
        BankBalance = address(this).balance;
        require(Received >= CreditsInfo[msg.sender]["MonthPayment"]);
        CreditsInfo[msg.sender]["CreditSummary"] -= Received;
        if(CreditsInfo[msg.sender]["CreditSummary"] <= 0){
            CreditsInfo[msg.sender]["TookCredit"] = 0;
            CreditsInfo[msg.sender]["MonthPayment"] = 0;
            CreditsInfo[msg.sender]["CreditSummary"] = 0;
            CreditsInfo[msg.sender]["Percent"] = 0;
        }
        else{
            CreditsInfo[msg.sender]["CreditSummary"] = int(CreditsInfo[msg.sender]["CreditSummary"]*(1 + CreditsInfo[msg.sender]["Percent"]) / 100);
        }
    }

    constructor()
    {
        owner = payable(msg.sender);
        stuff[owner] = true;
        BankBalance = address(this).balance;
        BaseTariffes();        
    }

    function BaseTariffes() private{                         // Подключаются базовые тарифы(придуманные владельцем банка)
        int[3] memory  a = [int(100), 10, 10];
        int[3] memory b = [int(1000), 10, 100];
        int[3] memory c = [int(10000), 10, 1000];

        tariffes.push(a);
        tariffes.push(b);
        tariffes.push(c);
    }

    function StuffApplication(string memory resume) external {        // Позволяет направлять резюме владельцу банка
        resumes[msg.sender] = resume;
    }

    function DeleteStuff(address[] memory arr) private OwnerOnly{     // Удаление работников
        for(uint i = 0; i<arr.length; i++){
            stuff[arr[i]] = false;
        }
    }

    function ResumeCheck(address[] memory checked, bool[] memory answers) private OwnerOnly {    //Решение о приеме/не приеме на работу
        require(answers.length == checked.length);
        for(uint i=0; i<answers.length; i++){
            stuff[checked[i]] = answers[i];
        }
    }

    function AddTariff(int[3] memory conditions) private OwnerOnly {              // Добавление нового кредитного тарифа по условиям тарифа
        tariffes.push(conditions);
    }

    function DeleteTariff(int tariffnumber) private OwnerOnly {                    // Удаление кредитного тарифа по номеру
        for(uint i = uint(tariffnumber); i<tariffes.length; i++){
            tariffes[i] = tariffes[i+1];
        }
        tariffes.pop();
    }

    function CreditDecision(address payable [] memory checked, bool[] memory answers, uint[] memory tariffnumbers) public payable StuffOnly{   //Выдача кредитов
                                                                                                                                //Вызов достпен только соотрудникам банка
        require(answers.length == checked.length);
        require(tariffnumbers.length == checked.length);
        for(uint i=0; i<answers.length; i++){
            if(answers[i]){
                CreditsInfo[checked[i]]["TookCredit"] = 1;
                CreditsInfo[checked[i]]["CreditSummary"] = tariffes[tariffnumbers[i]][0];
                CreditsInfo[checked[i]]["Percent"] = tariffes[tariffnumbers[i]][1];
                CreditsInfo[checked[i]]["MonthPayment"] = tariffes[tariffnumbers[i]][2];
                checked[i].transfer(uint(tariffes[tariffnumbers[i]][0]));
            }
        }
    }


}