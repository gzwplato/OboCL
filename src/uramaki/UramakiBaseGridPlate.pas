// This is part of the Obo Component Library
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// This software is distributed without any warranty.
//
// @author Domenico Mammola (mimmo71@gmail.com - www.mammola.net)
unit UramakiBaseGridPlate;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, Controls, ExtCtrls, DB, ComCtrls, {$IFDEF WINDOWS}Windows,{$ENDIF} DBGrids,
  Forms, Menus,
  {$IFDEF FPC}
  InterfaceBase,
  LCLIntf,
  LclType,
  LclProc,
  LResources,
  LMessages,
  {$ENDIF}

  UramakiBase,
  mVirtualDataSet, mFilterPanel, mFilter, mGridHelper, mDBGrid,
  mQuickReadOnlyVirtualDataSet, mXML, mVirtualDataSetInterfaces;

resourcestring
  SConfigureChildsUpdateModeCaption = 'Update of child widgets';
  SEnableAutomaticChildsUpdateCaption = 'Refresh them automatically';
  SDisableAutomaticChildsUpdateCaption = 'Do not refresh them automatically';
  SUpdateChildWidgetsBtnHint = 'Click to update child widgets';

const
  WM_USER_REFRESHCHILDS = WM_USER + 1;
  WM_USER_CLEARCHILDS = WM_USER + 2;

type

  TUramakiDBGridHelper = class;

  TDoFillRollFromDatasetRow = procedure (aUrakamiRoll : TUramakiRoll; const aDataset : TDataset) of object;

  TUramakiGridChildsAutomaticUpdateMode = (cuOnChangeSelection, cuDisabled);

  { TUramakiBaseGridPlate }

  TUramakiBaseGridPlate = class abstract (TUramakiPlate)
  strict private
    FAutomaticChildsUpdateMode : TUramakiGridChildsAutomaticUpdateMode;
    procedure SetAutomaticChildsUpdateMode(AValue: TUramakiGridChildsAutomaticUpdateMode);
    procedure DoUpdateChilds (Sender : TObject);
  protected
    FGrid: TmDBGrid;
    FDataset: TmVirtualDataset;
    FProvider : TReadOnlyVirtualDatasetProvider;
    FGridHelper : TUramakiDBGridHelper;
    FDatasource : TDatasource;
    FToolbar : TToolBar;
    FLastSelectedRow : integer;
    FFilterPanel : TmFilterPanel;

    // override these:
    function GetDataProvider : IVDListDataProvider; virtual; abstract;
    procedure ReloadData (aFilters : TmFilters); virtual; abstract;

    procedure CreateToolbar(aImageList : TImageList; aConfigureImageIndex, aRefreshChildsImageIndex : integer);
    procedure ConvertSelectionToUramakiRoll (aUramakiRoll : TUramakiRoll; aDoFillRollFromDatasetRow : TDoFillRollFromDatasetRow);
    procedure ProcessRefreshChilds(var Message: {$IFDEF FPC}TLMessage{$ELSE}TMessage{$ENDIF}); message WM_USER_REFRESHCHILDS;
    procedure ProcessClearChilds(var Message: {$IFDEF FPC}TLMessage{$ELSE}TMessage{$ENDIF}); message WM_USER_CLEARCHILDS;
    procedure OnSelectEditor(Sender: TObject; Column: TColumn; var Editor: TWinControl);
    procedure InvokeChildsRefresh;
    procedure InvokeChildsClear;

    procedure OnClearFilter (Sender : TObject);
    procedure OnExecuteFilter (Sender : TObject);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;

    procedure DisableControls;
    procedure EnableControls;
    procedure RefreshDataset;

    procedure LoadConfigurationFromXML (aXMLElement : TmXmlElement); override;
    procedure SaveConfigurationToXML (aXMLElement : TmXmlElement); override;
    procedure Clear; override;

    property AutomaticChildsUpdateMode : TUramakiGridChildsAutomaticUpdateMode read FAutomaticChildsUpdateMode write SetAutomaticChildsUpdateMode;
  end;

  { TUramakiDBGridHelper }

  TUramakiDBGridHelper = class(TmDBGridHelper)
  strict private
    FEnableAutomaticChildsUpdateMI : TMenuItem;
    FDisableAutomaticChildsUpdateMI : TMenuItem;

    FGridPlate : TUramakiBaseGridPlate;
    procedure OnEnableAutomaticChildsUpdate(Sender : TObject);
    procedure OnDisableAutomaticChildsUpdate(Sender : TObject);
  public
    constructor Create(aPlate : TUramakiBaseGridPlate); reintroduce;

    procedure CreateStandardConfigureMenu(aToolbar : TToolbar; const aConfigureImageIndex : integer); override;
  end;

implementation

{ TUramakiDBGridHelper }

constructor TUramakiDBGridHelper.Create(aPlate: TUramakiBaseGridPlate);
begin
  FGridPlate := aPlate;
  inherited Create(FGridPlate.FGrid, FGridPlate.FProvider.FormulaFields);
end;

procedure TUramakiDBGridHelper.CreateStandardConfigureMenu(aToolbar: TToolbar; const aConfigureImageIndex: integer);
var
  itm : TMenuItem;
begin
  inherited CreateStandardConfigureMenu(aToolbar, aConfigureImageIndex);
  itm := TMenuItem.Create(FConfigurePopupMenu);
  itm.Caption:= '-';
  FConfigurePopupMenu.Items.Add(itm);

  itm := TMenuItem.Create(FConfigurePopupMenu);
  itm.Caption:= SConfigureChildsUpdateModeCaption;
  FConfigurePopupMenu.Items.Add(itm);

  FEnableAutomaticChildsUpdateMI := TMenuItem.Create(itm);
  itm.Add(FEnableAutomaticChildsUpdateMI);
  FEnableAutomaticChildsUpdateMI.Caption := SEnableAutomaticChildsUpdateCaption;
  FEnableAutomaticChildsUpdateMI.Checked:= true;
  FEnableAutomaticChildsUpdateMI.OnClick:= Self.OnEnableAutomaticChildsUpdate;

  FDisableAutomaticChildsUpdateMI := TMenuItem.Create(itm);
  itm.Add(FDisableAutomaticChildsUpdateMI);
  FDisableAutomaticChildsUpdateMI.Caption := SDisableAutomaticChildsUpdateCaption;
  FDisableAutomaticChildsUpdateMI.Checked:= false;
  FDisableAutomaticChildsUpdateMI.OnClick:= Self.OnDisableAutomaticChildsUpdate;
end;


procedure TUramakiDBGridHelper.OnEnableAutomaticChildsUpdate(Sender: TObject);
begin
  FEnableAutomaticChildsUpdateMI.Checked:= true;
  FDisableAutomaticChildsUpdateMI.Checked:=false;
  FGridPlate.AutomaticChildsUpdateMode:= cuOnChangeSelection;
end;

procedure TUramakiDBGridHelper.OnDisableAutomaticChildsUpdate(Sender: TObject);
begin
  FEnableAutomaticChildsUpdateMI.Checked:= false;
  FDisableAutomaticChildsUpdateMI.Checked:= true;
  FGridPlate.AutomaticChildsUpdateMode:= cuDisabled;
end;


{ TUramakiBaseGridPlate }

procedure TUramakiBaseGridPlate.SetAutomaticChildsUpdateMode(AValue: TUramakiGridChildsAutomaticUpdateMode);
begin
  FAutomaticChildsUpdateMode:=AValue;
  if FAutomaticChildsUpdateMode = cuOnChangeSelection then
    FGrid.OnSelectEditor:= Self.OnSelectEditor
  else
    FGrid.OnSelectEditor:= nil;
end;

procedure TUramakiBaseGridPlate.DoUpdateChilds(Sender : TObject);
begin
  if FAutomaticChildsUpdateMode = cuOnChangeSelection then
  begin
    if FLastSelectedRow <> FGrid.Row then
    begin
      FLastSelectedRow := FGrid.Row;
      if Assigned(Self.Parent) then
        InvokeChildsRefresh;
    end;
  end
  else
  begin
    FLastSelectedRow:= -1;
    if Assigned(Self.Parent) then
      InvokeChildsRefresh;
  end;
end;

procedure TUramakiBaseGridPlate.CreateToolbar(aImageList : TImageList; aConfigureImageIndex, aRefreshChildsImageIndex : integer);
var
  tmp : TToolButton;
begin
  FToolbar := TToolBar.Create(Self);
  FToolbar.Parent := Self;
  FToolbar.Align:= alTop;
  FToolbar.Images := aImageList;
  FToolbar.ShowHint:= true;
  FGridHelper.CreateStandardConfigureMenu(FToolbar, aConfigureImageIndex);

  tmp := TToolButton.Create(FToolbar);
  tmp.Style := tbsButton;
  tmp.OnClick:= Self.DoUpdateChilds;
  tmp.ImageIndex:= aRefreshChildsImageIndex;
  tmp.Parent := FToolbar;
  tmp.Hint := SUpdateChildWidgetsBtnHint;
  tmp.Enabled:= true;

  tmp := TToolButton.Create(FToolbar);
  tmp.Style := tbsSeparator;
  tmp.Parent := FToolbar;
end;

procedure TUramakiBaseGridPlate.ConvertSelectionToUramakiRoll(aUramakiRoll: TUramakiRoll; aDoFillRollFromDatasetRow : TDoFillRollFromDatasetRow);
var
  tmpBookmark : TBookMark;
  i : integer;
begin
  if FDataset.ControlsDisabled then
    exit;

  if (FGrid.SelectedRows.Count > 1) then
  begin
    FGrid.BeginUpdate;
    try
      tmpBookmark := FDataset.Bookmark;
      try
        for i := 0 to FGrid.SelectedRows.Count - 1 do
        begin
          FDataset.GotoBookmark(FGrid.SelectedRows[i]);
          aDoFillRollFromDatasetRow(aUramakiRoll, FDataset);
        end;
      finally
        FDataset.GotoBookmark(tmpBookmark);
      end;
    finally
      FGrid.EndUpdate(true);
    end;
  end
  else //if FGrid.SelectedRows.Count =  1 then
  begin
    aDoFillRollFromDatasetRow(aUramakiRoll, FDataset);
  end;
end;

procedure TUramakiBaseGridPlate.ProcessRefreshChilds(var Message: {$IFDEF FPC}TLMessage{$ELSE}TMessage{$ENDIF});
begin
  FGrid.OnSelectEditor:= nil;
  try
    EngineMediator.PleaseRefreshMyChilds(Self);
  finally
    if AutomaticChildsUpdateMode = cuOnChangeSelection then
      FGrid.OnSelectEditor:= Self.OnSelectEditor;
  end;
end;

procedure TUramakiBaseGridPlate.ProcessClearChilds(var Message: TLMessage);
begin
  EngineMediator.PleaseClearMyChilds(Self);
end;

procedure TUramakiBaseGridPlate.OnSelectEditor(Sender: TObject; Column: TColumn; var Editor: TWinControl);
begin
  DoUpdateChilds(nil);
end;

procedure TUramakiBaseGridPlate.InvokeChildsRefresh;
begin
  PostMessage(Self.Handle, WM_USER_REFRESHCHILDS, 0, 0);
end;

procedure TUramakiBaseGridPlate.InvokeChildsClear;
begin
  PostMessage(Self.Handle, WM_USER_CLEARCHILDS, 0, 0);
end;

procedure TUramakiBaseGridPlate.OnClearFilter(Sender: TObject);
begin
  if Assigned(FFilterPanel) then
  begin
    FFilterPanel.ClearAll();
    Self.Clear;
  end;
end;

procedure TUramakiBaseGridPlate.OnExecuteFilter(Sender: TObject);
var
  tmpFilters : TmFilters;
  oldCursor : TCursor;
begin
  Self.DisableControls;
  try
    OldCursor := Screen.Cursor;
    try
      Screen.Cursor := crHourGlass;

      tmpFilters := TmFilters.Create;
      try
        FFilterPanel.GetFilters(tmpFilters);
        Self.ReloadData(tmpFilters);
        RefreshDataset;
      finally
        tmpFilters.Free;
      end;
    finally
      Screen.Cursor := OldCursor;
    end;
  finally
    Self.EnableControls;
  end;
  FLastSelectedRow := -1;
  if AutomaticChildsUpdateMode = cuOnChangeSelection then
    InvokeChildsRefresh
  else
    InvokeChildsClear;
end;

procedure TUramakiBaseGridPlate.DisableControls;
begin
  FDataset.DisableControls;
end;

procedure TUramakiBaseGridPlate.EnableControls;
begin
  FDataset.EnableControls;
end;

procedure TUramakiBaseGridPlate.RefreshDataset;
begin
  FGrid.SelectedRows.Clear;
  FGrid.SelectedIndex:= -1;
  FLastSelectedRow := -1;
  FDataset.Refresh;
end;

constructor TUramakiBaseGridPlate.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FGrid := TmDBGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align:= alClient;
  FDatasource:= TDataSource.Create(Self);
  FGrid.DataSource := FDataSource;


  FDataset := TmVirtualDataset.Create(nil);
  FProvider := TReadOnlyVirtualDatasetProvider.Create;
  FDataset.DatasetDataProvider := FProvider;
  FDatasource.DataSet := FDataset;

  FGridHelper:= TUramakiDBGridHelper.Create(Self);
  FGridHelper.SetupGrid;
  FGrid.SortManager := Self.FDataset.SortManager;
  FGrid.FilterManager := Self.FDataset.FilterManager;
  FGrid.ColumnsHeaderMenuVisible:= true;

  FLastSelectedRow:=-1;
  Self.AutomaticChildsUpdateMode:= cuOnChangeSelection;
end;

destructor TUramakiBaseGridPlate.Destroy;
begin
  FGridHelper.Free;
  FProvider.Free;
  FDataset.Free;

  inherited Destroy;
end;

procedure TUramakiBaseGridPlate.LoadConfigurationFromXML(aXMLElement: TmXmlElement);
var
  Cursor : TmXmlElementCursor;
begin
  Cursor := TmXmlElementCursor.Create(aXMLElement, 'gridConfiguration');
  try
    if Cursor.Count > 0 then
      FGridHelper.LoadSettingsFromXML(Cursor.Elements[0]);
  finally
    Cursor.Free;
  end;
  Cursor := TmXmlElementCursor.Create(aXMLElement, 'refreshChildsConfiguration');
  try
    if Cursor.Count > 0 then
    begin
      if Cursor.Elements[0].GetBooleanAttribute('automatic', true) then
        Self.AutomaticChildsUpdateMode:= cuOnChangeSelection
      else
        Self.AutomaticChildsUpdateMode:= cuDisabled;
    end;
  finally
    Cursor.Free;
  end;
end;

procedure TUramakiBaseGridPlate.SaveConfigurationToXML(aXMLElement: TmXmlElement);
var
  tmpElement : TmXmlElement;
begin
  FGridHelper.SaveSettingsToXML(aXMLElement.AddElement('gridConfiguration'));
  tmpElement := aXMLElement.AddElement('refreshChildsConfiguration');
  tmpElement.SetBooleanAttribute('automatic', (Self.AutomaticChildsUpdateMode = cuOnChangeSelection));
end;

procedure TUramakiBaseGridPlate.Clear;
begin
  Self.DisableControls;
  try
    GetDataProvider.Clear();
    RefreshDataset;
  finally
    Self.EnableControls;
  end;
  FLastSelectedRow := -1;
  InvokeChildsClear;
end;



end.
