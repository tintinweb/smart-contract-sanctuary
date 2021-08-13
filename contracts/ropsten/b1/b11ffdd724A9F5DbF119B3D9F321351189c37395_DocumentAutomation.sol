/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

pragma solidity ^0.6.4;


contract DocumentAutomation
{
	address public customer;
	address public rosgeo;
	address public auditor;
	address public executor;

	bytes32 public hashOfTor; /// Хэш документа ТЗ
	bytes32 public hashOfProjectShedule; /// Хэш документа плана работ
	bytes32 public hashOfReportByCustomer; /// Хэш документа отчета заказчика
	bytes32 public hashOfReportByExecutor; /// Хэш документа отчета исполнителя
	bytes32 public hashOfFinalReportByExecutor; /// Хэш финального документа отчета исполнителя
	bytes32 public hashOfReportByRosgeo; /// Хэш документа отчета Росгео

	/// Группа булевых значений для контроля хода исполнения контракта
	bool public isTorProposedByCustomer;
	bool public isTorApprovedByRosgeo;
	bool public isProjectSheduleProposedByExecutor;
	bool public isContractedByCustomer;
	bool public isReportedByCustomer;
	bool public isReportedByExecutor;
	bool public isReportedByRosgeo;
	bool public isFinalyReportedByExeutor;
	bool public isApprovedByRosgeo;
	bool public isActedByExecutor;
	bool public isClosedContract;

	event ProposeTor(address indexed _customer, uint256 indexed _time, bytes32 _hashOfTor); 
	event ApproveTor(address indexed _rosgeo, uint256 indexed _time);
	event ProposeProjectShedule(address indexed _executor, uint256 indexed _time, bytes32 _hashOfProjectShedule);
	event ContractByCustomer(address indexed _customer, uint256 indexed _time);
	event ReportByCustomer(address indexed _customer, uint256 indexed _time, bytes32 _hashOfReportByCustomer);
	event ReportByExecutor(address indexed _executor, uint256 indexed _time, bytes32 _hashOfReportByExecutor);
	event ReportByRosgeo(address indexed _rosgeo, uint256 indexed _time, bytes32 _hashOfReportByRosgeo);
	event FinalReportByExecutor(address indexed _executor, uint256 indexed _time, bytes32 _hashOfFinalReportByExecutor);
	event ApproveByRosgeo(address indexed _rosgeo, uint256 indexed _time);
	event ActByExecutor(address indexed _executor, uint256 indexed _time);
	event CloseContract(address indexed _customer, uint256 indexed _time);

	modifier only(address role)
	{
		require(msg.sender == role);
		_;
	}

	constructor () public
	{
	}

	function init(address _customer, address _rosgeo, address _auditor, address _executor) public
	{
		customer = _customer;
		rosgeo = _rosgeo;
		auditor = _auditor;
		executor = _executor;
	}

	/// @notice Выдвинуть ТЗ (вызывает только заказчик)
	/// @param  _hashOfTor хэш документа ТЗ
	function proposeTor(bytes32 _hashOfTor) only(customer) public
	{
		hashOfTor = _hashOfTor;
		isTorProposedByCustomer = true;
		emit ProposeTor(customer, now, hashOfTor);
	}

	/// @notice Подтвердить ТЗ (вызывает только Росгео)
	function approveTor() only(rosgeo) public
	{
		require(isTorProposedByCustomer, "Customer has not proposed Tor yet");
		isTorApprovedByRosgeo = true;
		emit ApproveTor(rosgeo, now);
	}

	/// @notice Выдвинуть план работ (вызывает только исполнитель)
	/// @param  _hashOfProjectShedule хэш документа плана работ
	function proposeProjectShedule(bytes32 _hashOfProjectShedule) only(executor) public
	{
		require(isTorApprovedByRosgeo, "Rosgeo has not approved Tor yet");
		hashOfProjectShedule = _hashOfProjectShedule;
		isProjectSheduleProposedByExecutor = true;
		emit ProposeProjectShedule(executor, now, hashOfProjectShedule);
	}

	/// @notice Подтверждение выполнения от заказчика
	function contractByCustomer() only(customer) public
	{
		require(isProjectSheduleProposedByExecutor, "Executor has not proposed shedule yet");
		isContractedByCustomer = true;
		emit ContractByCustomer(customer, now);
	}

	/// @notice Отчетность от заказчика
	/// @param  _hashOfReportByCustomer хэш документа отчетности от заказчика
	function reportByCustomer(bytes32 _hashOfReportByCustomer) only(customer) public
	{
		require(isContractedByCustomer, "Contract has not been confirmed by customer yet");
		isReportedByCustomer = true;
		hashOfReportByCustomer = _hashOfReportByCustomer;
		emit ReportByCustomer(customer, now, hashOfReportByCustomer);
	}

	/// @notice Отчетность от исполнителя
	/// @param  _hashOfReportByExecutor хэш документа отчетности от исполнителя
	function reportByExecutor(bytes32 _hashOfReportByExecutor) only(executor) public
	{
		require(isReportedByCustomer, "Customer has not reported yet");
		hashOfReportByExecutor = _hashOfReportByExecutor;
		isReportedByExecutor = true;
		emit ReportByExecutor(executor, now, hashOfReportByExecutor);
	}

	/// @notice Отчетность от Росгео
	/// @param  _hashOfReportByRosgeo хэш документа отчетности от Росгео
	function reportByRosgeo(bytes32 _hashOfReportByRosgeo) only(rosgeo) public
	{
		require(isReportedByExecutor, "Executor has not reported yet");
		hashOfReportByRosgeo = _hashOfReportByRosgeo;
		isReportedByRosgeo = true;
		emit ReportByRosgeo(rosgeo, now, hashOfReportByRosgeo);
	}

	/// @notice Финальный отчет от исполнителя
	/// @param  _hashOfFinalReportByExecutor хэш документа заключительного отчета от исполнителя
	function finalReportByExecutor(bytes32 _hashOfFinalReportByExecutor) only(executor) public
	{	
		require(isReportedByRosgeo, "Rosgeo has not proposed report yet");
		hashOfFinalReportByExecutor = _hashOfFinalReportByExecutor;
		isFinalyReportedByExeutor = true;
		emit FinalReportByExecutor(executor, now, hashOfFinalReportByExecutor);
	}

	/// @notice Подтверждение отчета Росгео
	function approveByRosgeo() only(rosgeo) public
	{
		require(isFinalyReportedByExeutor, "Executor has not proposed final report yet");
		isApprovedByRosgeo = true;
		emit ApproveByRosgeo(rosgeo, now);
	}

	/// @notice Активирование исполнителем
	function actByExecutor() only(executor) public
	{
		require(isApprovedByRosgeo, "Rosgeo has not approved report yet");
		isActedByExecutor = true;
		emit ActByExecutor(executor, now);
	}

	/// @notice Закрытие контракта (вызывает только заказчик)
	function closeContract() only(customer) public
	{
		require(isActedByExecutor, "Contract is not acted by customer");
		isClosedContract = true;
		emit CloseContract(customer, now);
	}
}