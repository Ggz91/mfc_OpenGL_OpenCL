// SAAParamDlg.cpp : 实现文件
//

#include "stdafx.h"
#include "mfc_OpenGL_OpenCL.h"
#include "SAAParamDlg.h"
#include "afxdialogex.h"
#include "Log.h"

// CSAAParamDlg 对话框

IMPLEMENT_DYNAMIC(CSAAParamDlg, CDialogEx)

CSAAParamDlg::CSAAParamDlg(CWnd* pParent /*=NULL*/)
	: CDialogEx(CSAAParamDlg::IDD, pParent)
{

}

CSAAParamDlg::~CSAAParamDlg()
{
}

void CSAAParamDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_ORIGINTEM_EDIT, m_OriginTmpEdt);
	DDX_Control(pDX, IDC_THRESHOLDTEM_EDIT, m_ThresholdTmpEdt);
	DDX_Control(pDX, IDC_SAMPLE_EDIT, m_SingleSampleCount);
	DDX_Control(pDX, IDC_DESSPEED_EDIT, m_DecSpeed);
}


BEGIN_MESSAGE_MAP(CSAAParamDlg, CDialogEx)
	ON_BN_CLICKED(IDC_SAAENTER_BUTTON, &CSAAParamDlg::OnBnClickedSaaenterButton)
END_MESSAGE_MAP()


// CSAAParamDlg 消息处理程序


void CSAAParamDlg::OnBnClickedSaaenterButton()
{
	// TODO: 在此添加控件通知处理程序代码
	CString originTem = GetEdtContent(&m_OriginTmpEdt, _T("初始温度设置"));
	CString thresholdTem = GetEdtContent(&m_ThresholdTmpEdt, _T("阈值温度设置"));
	CString singleSampleCount = GetEdtContent(&m_SingleSampleCount, _T("采样次数设置"));
	CString desSpeed = GetEdtContent(&m_DecSpeed, _T("下降参数设置"));

	if ( originTem == CString(_T("")) | thresholdTem == CString(_T("")) | singleSampleCount == CString(_T("")) | desSpeed == CString(_T(""))) return;

	m_OpenCLCom->SetSAASAHParam(StrToInt(originTem.GetBuffer()),
								StrToInt(thresholdTem.GetBuffer()),
								StrToInt(singleSampleCount.GetBuffer()),
								StrToFloat(CStrToStr(desSpeed)));
	CDialogEx::OnOK();
}

CString CSAAParamDlg::GetEdtContent(CEdit* edt, wchar_t* errInfo)
{
	//auto edt = dynamic_cast<CEdit*>(GetDlgItem(idc));
	wchar_t* content = new wchar_t[edt->LineLength()];
	int len = edt->GetLine(0, content, edt->LineLength());
	if (len <= 0)
	{
		CString csErrInfo(errInfo);
		csErrInfo = _T("Error:") + csErrInfo;
		systemLog->PrintStatus(csErrInfo.GetBuffer());
		return CString(_T(""));
	}

	return CString(content, len);
}

void CSAAParamDlg::SetOpenCLComPtr(COpenCLCompute* ptr)
{
	m_OpenCLCom = ptr;
}