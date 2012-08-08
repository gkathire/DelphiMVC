unit WMLaunchForm;

interface

uses {$IF CompilerVersion > 22.0}Winapi.Windows,{$ELSE}Windows,{$IFEND} {$IF CompilerVersion > 22.0}Winapi.Messages,{$ELSE}Messages,{$IFEND} {$IF CompilerVersion > 22.0}System.SysUtils,{$ELSE}SysUtils,{$IFEND}{$IF CompilerVersion > 22.0}System.Variants,{$ELSE}Variants,{$IFEND}
  {$IF CompilerVersion > 22.0}System.Classes,{$ELSE}Classes,{$IFEND} {$IF CompilerVersion > 22.0}Vcl.Graphics,{$ELSE}Graphics,{$IFEND} {$IF CompilerVersion > 22.0}Vcl.Controls,{$ELSE}Controls,{$IFEND} {$IF CompilerVersion > 22.0}Vcl.Forms,{$ELSE}Forms,{$IFEND} {$IF CompilerVersion > 22.0}Vcl.Dialogs,{$ELSE}Dialogs,{$IFEND}
  {$IF CompilerVersion > 22.0}Vcl.AppEvnts,{$ELSE}AppEvnts,{$IFEND} {$IF CompilerVersion > 22.0}Vcl.StdCtrls,{$ELSE}StdCtrls,{$IFEND} IdHTTPWebBrokerBridge, {$IF CompilerVersion > 22.0}Web.HTTPApp{$ELSE}HTTPApp{$IFEND};

type
  TWMLaunchFrm = class(TForm)
    ButtonStart: TButton;
    ButtonStop: TButton;
    EditPort: TEdit;
    Label1: TLabel;
    ApplicationEvents1: TApplicationEvents;
    ButtonOpenBrowser: TButton;
    procedure FormCreate(Sender: TObject);
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    procedure ButtonStartClick(Sender: TObject);
    procedure ButtonStopClick(Sender: TObject);
    procedure ButtonOpenBrowserClick(Sender: TObject);
  private
    FServer: TIdHTTPWebBrokerBridge;
    procedure StartServer;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  WMLaunchFrm: TWMLaunchFrm;

implementation

{$R *.dfm}

uses
  {$IF CompilerVersion > 22.0}Winapi.ShellApi{$ELSE}ShellApi{$IFEND};

procedure TWMLaunchFrm.ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
begin
  ButtonStart.Enabled := not FServer.Active;
  ButtonStop.Enabled := FServer.Active;
  EditPort.Enabled := not FServer.Active;
end;

procedure TWMLaunchFrm.ButtonOpenBrowserClick(Sender: TObject);
var
  LURL: string;
begin
  StartServer;
  LURL := Format('http://localhost:%s', [EditPort.Text]);
  ShellExecute(0,
        nil,
        PChar(LURL), nil, nil, SW_SHOWNOACTIVATE);
end;

procedure TWMLaunchFrm.ButtonStartClick(Sender: TObject);
begin
  StartServer;
end;

procedure TWMLaunchFrm.ButtonStopClick(Sender: TObject);
begin
  FServer.Active := False;
  FServer.Bindings.Clear;
end;

procedure TWMLaunchFrm.FormCreate(Sender: TObject);
begin
  FServer := TIdHTTPWebBrokerBridge.Create(Self);
end;

procedure TWMLaunchFrm.StartServer;
begin
  if not FServer.Active then
  begin
    FServer.Bindings.Clear;
    FServer.DefaultPort := StrToInt(EditPort.Text);
    FServer.Active := True;
  end;
end;

end.
