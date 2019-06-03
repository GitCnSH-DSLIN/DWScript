{**********************************************************************}
{                                                                      }
{    "The contents of this file are subject to the Mozilla Public      }
{    License Version 1.1 (the "License"); you may not use this         }
{    file except in compliance with the License. You may obtain        }
{    a copy of the License at http://www.mozilla.org/MPL/              }
{                                                                      }
{    Software distributed under the License is distributed on an       }
{    "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express       }
{    or implied. See the License for the specific language             }
{    governing rights and limitations under the License.               }
{                                                                      }
{    The Initial Developer of the Original Code is Matthias            }
{    Ackermann. For other initial contributors, see contributors.txt   }
{    Subsequent portions Copyright Creative IT.                        }
{                                                                      }
{    Current maintainer: Eric Grange                                   }
{                                                                      }
{**********************************************************************}
unit dwsCoreExprs;

{$I dws.inc}

interface

uses
   Classes, SysUtils, Variants,
   dwsUtils, dwsXPlatform, dwsUnicode,
   dwsDataContext, dwsCompilerContext, dwsExprList,
   dwsSymbols, dwsErrors, dwsStrings, dwsConvExprs,
   dwsStack, dwsExprs, dwsScriptSource,
   dwsConstExprs, dwsTokenizer, dwsUnitSymbols;

type

   TVarExpr = class (TDataExpr)
      protected
         FStackAddr : Integer;
         FDataSym : TDataSymbol;

      public
         constructor Create(dataSym : TDataSymbol);
         class function CreateTyped(context : TdwsCompilerContext; dataSym : TDataSymbol) : TVarExpr;
         procedure Orphan(context : TdwsCompilerContext); override;

         procedure AssignDataExpr(exec : TdwsExecution; DataExpr: TDataExpr); override;
         procedure AssignExpr(exec : TdwsExecution; Expr: TTypedExpr); override;
         procedure AssignValue(exec : TdwsExecution; const value : Variant); override;
         procedure AssignValueAsInteger(exec : TdwsExecution; const value : Int64); override;
         procedure AssignValueAsBoolean(exec : TdwsExecution; const value : Boolean); override;
         procedure AssignValueAsFloat(exec : TdwsExecution; const value : Double); override;
         procedure AssignValueAsString(exec : TdwsExecution; const value : String); override;
         procedure AssignValueAsScriptObj(exec : TdwsExecution; const value : IScriptObj); override;

         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;

         procedure GetDataPtr(exec : TdwsExecution; var result : IDataContext); override;
         procedure GetRelativeDataPtr(exec : TdwsExecution; var result : IDataContext); override;

         function IsWritable : Boolean; override;

         function ReferencesVariable(varSymbol : TDataSymbol) : Boolean; override;

         function SameDataExpr(expr : TTypedExpr) : Boolean; override;
         function DataSymbol : TDataSymbol; override;

         function SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr; override;

         property StackAddr : Integer read FStackAddr;
         property DataSym : TDataSymbol read FDataSym write FDataSym;
   end;

   TBaseTypeVarExpr = class (TVarExpr)
      public
         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
         procedure EvalAsInterface(exec : TdwsExecution; var result : IUnknown); override;
   end;

   TIntVarExpr = class (TBaseTypeVarExpr)
      public
         procedure AssignExpr(exec : TdwsExecution; Expr: TTypedExpr); override;
         procedure AssignValue(exec : TdwsExecution; const Value: Variant); override;
         procedure AssignValueAsInteger(exec : TdwsExecution; const Value: Int64); override;

         procedure IncValue(exec : TdwsExecution; const value: Int64);

         function  EvalAsInteger(exec : TdwsExecution) : Int64; override;
         function  EvalAsFloat(exec : TdwsExecution) : Double; override;
         function  EvalAsPInteger(exec : TdwsExecution) : PInt64; inline;
   end;

   TFloatVarExpr = class sealed (TBaseTypeVarExpr)
      protected
      public
         procedure AssignExpr(exec : TdwsExecution; Expr: TTypedExpr); override;
         procedure AssignValue(exec : TdwsExecution; const Value: Variant); override;
         procedure AssignValueAsFloat(exec : TdwsExecution; const Value: Double); override;
         function  EvalAsFloat(exec : TdwsExecution) : Double; override;
   end;

   TStrVarExpr = class sealed (TBaseTypeVarExpr)
      protected
      public
         procedure AssignExpr(exec : TdwsExecution; Expr: TTypedExpr); override;
         procedure AssignValue(exec : TdwsExecution; const Value: Variant); override;
         procedure AssignValueAsString(exec : TdwsExecution; const Value: String); override;
         procedure AssignValueAsUnicodeString(exec : TdwsExecution; const Value: UnicodeString); inline;
         procedure AssignValueAsWideChar(exec : TdwsExecution; aChar : WideChar);
         function  SetChar(exec : TdwsExecution; index : Integer; c : WideChar) : Boolean;
         procedure EvalAsString(exec : TdwsExecution; var result : String); override;
         procedure Append(exec : TdwsExecution; const value : String);
         function EvalAsPString(exec : TdwsExecution) : PString; inline;
   end;

   TBoolVarExpr = class (TBaseTypeVarExpr)
      protected
      public
         procedure AssignExpr(exec : TdwsExecution; Expr: TTypedExpr); override;
         procedure AssignValue(exec : TdwsExecution; const Value: Variant); override;
         procedure AssignValueAsBoolean(exec : TdwsExecution; const value : Boolean); override;
         function  EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
         function  EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   TObjectVarExpr = class (TBaseTypeVarExpr)
      public
         procedure AssignExpr(exec : TdwsExecution; Expr: TTypedExpr); override;
         procedure EvalAsScriptObj(exec : TdwsExecution; var Result : IScriptObj); override;
         procedure EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray); override;
   end;

   TSelfVarExpr = class (TVarExpr)
      public
         function IsWritable : Boolean; override;
   end;

   TSelfObjectVarExpr = class (TObjectVarExpr)
      public
         function IsWritable : Boolean; override;
   end;

   TVarParentExpr = class(TVarExpr)
      protected
         FScriptPos : TScriptPos;
         FLevel: Integer;

      public
         constructor Create(const aScriptPos: TScriptPos; dataSym : TDataSymbol);
         procedure GetDataPtr(exec : TdwsExecution; var result : IDataContext); override;
         procedure GetRelativeDataPtr(exec : TdwsExecution; var result : IDataContext); override;

         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
         function EvalAsFloat(exec : TdwsExecution) : Double; override;

         function ScriptPos : TScriptPos; override;

         property Level : Integer read FLevel;
   end;

   TExternalVarExpr = class(TVarExpr)
      public
         function IsExternal : Boolean; override;
         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
   end;

   // Encapsulates a lazy parameter
   TLazyParamExpr = class(TTypedExpr)
      private
         FDataSym : TLazyParamSymbol;
         FStackAddr : Integer;
         FLevel : Integer;

      public
         constructor Create(context : TdwsCompilerContext; dataSym : TLazyParamSymbol);
         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;

         function SameDataExpr(expr : TTypedExpr) : Boolean; override;

         property DataSym : TLazyParamSymbol read FDataSym write FDataSym;
         property StackAddr : Integer read FStackAddr write FStackAddr;
         property Level : Integer read FLevel write FLevel;
   end;

   // Encapsulates a var parameter
   TByRefParamExpr = class (TVarExpr)
      public
         constructor CreateFromVarExpr(expr : TVarExpr);

         function GetVarParamDataAsPointer(exec : TdwsExecution) : Pointer; inline;
         procedure GetVarParamData(exec : TdwsExecution; var result : IDataContext);
         function GetVarParamEval(exec : TdwsExecution) : PVariant; inline;

         procedure GetDataPtr(exec : TdwsExecution; var result : IDataContext); override;
         procedure GetRelativeDataPtr(exec : TdwsExecution; var result : IDataContext); override;

         procedure AssignDataExpr(exec : TdwsExecution; dataExpr: TDataExpr); override;
         procedure AssignExpr(exec : TdwsExecution; Expr: TTypedExpr); override;
         procedure AssignValue(exec : TdwsExecution; const Value: Variant); override;
         procedure AssignValueAsInteger(exec : TdwsExecution; const value : Int64); override;
         procedure AssignValueAsBoolean(exec : TdwsExecution; const value : Boolean); override;
         procedure AssignValueAsFloat(exec : TdwsExecution; const value : Double); override;
         procedure AssignValueAsString(exec : TdwsExecution; const value : String); override;
         procedure AssignValueAsScriptObj(exec : TdwsExecution; const value : IScriptObj); override;

         procedure EvalAsVariant(exec : TdwsExecution; var result : Variant); override;
         procedure EvalAsInterface(exec : TdwsExecution; var result : IUnknown); override;
         function  EvalAsFloat(exec : TdwsExecution) : Double; override;

         function SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr; override;
   end;

   TVarParamExpr = class sealed (TByRefParamExpr)
      public
         function SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr; override;
   end;

   TConstParamExpr = class sealed (TByRefParamExpr)
      public
         function IsWritable : Boolean; override;
         function SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr; override;
   end;

   // Encapsulates a var parameter from the parent context
   TByRefParentParamExpr = class(TByRefParamExpr)
      protected
         FLevel : Integer;

      public
         constructor Create(dataSym : TDataSymbol);

         procedure GetDataPtr(exec : TdwsExecution; var result : IDataContext); override;

         procedure AssignExpr(exec : TdwsExecution; Expr: TTypedExpr); override;

         procedure EvalAsVariant(exec : TdwsExecution; var result : Variant); override;
         procedure EvalAsInterface(exec : TdwsExecution; var result : IUnknown); override;
         function  EvalAsFloat(exec : TdwsExecution) : Double; override;
         function  EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   TVarParamParentExpr = class(TByRefParentParamExpr)
   end;

   TConstParamParentExpr = class(TByRefParentParamExpr)
      public
         function IsWritable : Boolean; override;
   end;

   // TResourceStringExpr
   //
   // Returns a localized version of a resourcestring
   TResourceStringExpr = class sealed (TTypedExpr)
      private
         FResSymbol : TResourceStringSymbol;
         FScriptPos : TScriptPos;

      public
         constructor Create(context : TdwsCompilerContext; const aScriptPos : TScriptPos; aRes : TResourceStringSymbol);

         function ScriptPos : TScriptPos; override;

         procedure EvalAsVariant(exec : TdwsExecution; var result : Variant); override;
         procedure EvalAsString(exec : TdwsExecution; var result : String); override;

         property ResSymbol : TResourceStringSymbol read FResSymbol;
   end;

   // Array expressions x[index]
   TArrayExpr = class(TPosDataExpr)
      protected
         FBaseExpr : TDataExpr;
         FIndexExpr : TTypedExpr;
         FElementSize : Integer;

         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;
         function GetBaseType : TTypeSymbol; override;

      public
         constructor Create(const aScriptPos: TScriptPos;
                            BaseExpr: TDataExpr; IndexExpr: TTypedExpr;
                            arraySymbol : TArraySymbol);
         destructor Destroy; override;
         procedure Orphan(context : TdwsCompilerContext); override;

         function IsWritable : Boolean; override;

         function SameDataExpr(expr : TTypedExpr) : Boolean; override;

         property BaseExpr : TDataExpr read FBaseExpr;
         property IndexExpr : TTypedExpr read FIndexExpr;
   end;

   EScriptOutOfBounds = class (EScriptError);

   // Array expressions x[index] for static arrays
   TStaticArrayExpr = class (TArrayExpr)
      private
         FLowBound : Integer;
         FCount : Integer;

      protected
         function GetIndex(exec : TdwsExecution) : Integer; virtual;

         function GetIsConstant : Boolean; override;

      public
         constructor Create(const aScriptPos: TScriptPos;
                            baseExpr : TDataExpr; indexExpr : TTypedExpr;
                            arraySymbol : TStaticArraySymbol);

         function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;

         procedure AssignExpr(exec : TdwsExecution; expr : TTypedExpr); override;
         procedure AssignValueAsInteger(exec : TdwsExecution; const value : Int64); override;
         procedure AssignValueAsBoolean(exec : TdwsExecution; const value : Boolean); override;
         procedure AssignValueAsFloat(exec : TdwsExecution; const value : Double); override;
         procedure AssignValueAsString(exec : TdwsExecution; const value: String); override;

         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
         function EvalAsFloat(exec : TdwsExecution) : Double; override;
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
         procedure EvalAsVariant(exec : TdwsExecution; var result : Variant); override;
         procedure EvalAsString(exec : TdwsExecution; var result : String); override;

         procedure GetDataPtr(exec : TdwsExecution; var result : IDataContext); override;

         property LowBound : Integer read FLowBound write FLowBound;
         property Count : Integer read FCount write FCount;
   end;

   // Array expressions x[bool] for static arrays
   TStaticArrayBoolExpr = class (TStaticArrayExpr)
      protected
         function GetIndex(exec : TdwsExecution) : Integer; override;
   end;

   // Array expressions x[index] for open arrays
   TOpenArrayExpr = class(TArrayExpr)
      public
         procedure GetDataPtr(exec : TdwsExecution; var result : IDataContext); override;
         function IsWritable : Boolean; override;
   end;

   // Array expressions: x[index0] for dynamic arrays
   TDynamicArrayExpr = class(TArrayExpr)
      protected
         function EvalItem(exec : TdwsExecution; var dyn : IScriptDynArray) : PVariant;

      public
         procedure GetDataPtr(exec : TdwsExecution; var result : IDataContext); override;

         function  EvalAsInteger(exec : TdwsExecution) : Int64; override;
         function  EvalAsFloat(exec : TdwsExecution) : Double; override;
         procedure EvalAsVariant(exec : TdwsExecution; var result : Variant); override;
         procedure EvalAsString(exec : TdwsExecution; var result : String); override;

         function  SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr; override;

         procedure CreateArrayElementDataContext(exec : TdwsExecution; var result : IDataContext);
   end;

   // Array expressions: x[index0] for dynamic arrays where BaseExpr is a TObjectVarExpr
   TDynamicArrayVarExpr = class sealed (TDynamicArrayExpr)
      protected
         function EvalItem(exec : TdwsExecution) : PVariant;

      public
         function  EvalAsInteger(exec : TdwsExecution) : Int64; override;
         function  EvalAsFloat(exec : TdwsExecution) : Double; override;
         procedure EvalAsString(exec : TdwsExecution; var result : String); override;

         function  SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr; override;
   end;

   // array[index]:=val for dynamic arrays
   TDynamicArraySetExpr = class(TNoResultExpr)
      private
         FArrayExpr : TTypedExpr;
         FIndexExpr : TTypedExpr;
         FValueExpr : TTypedExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                            arrayExpr, indexExpr, valueExpr : TTypedExpr);
         destructor Destroy; override;

         procedure EvalNoResult(exec : TdwsExecution); override;

         property ArrayExpr : TTypedExpr read FArrayExpr;
         property IndexExpr : TTypedExpr read FIndexExpr;
         property ValueExpr : TTypedExpr read FValueExpr;
   end;

   // array[index]:=val for dynamic arrays when ArrayExpr is TObjectVarExpr and size=1
   TDynamicArraySetVarExpr = class(TDynamicArraySetExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // array[index]:=val for dynamic arrays with elements larger than size = 1
   TDynamicArraySetDataExpr = class(TDynamicArraySetExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // Associative array x[key] for expressions
   TAssociativeArrayGetExpr = class (TPosDataExpr)
      protected
         FBaseExpr : TDataExpr;
         FKeyExpr : TTypedExpr;
         FElementSize : Integer;

         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;
         function GetBaseType : TTypeSymbol; override;

      public
         constructor Create(const aScriptPos: TScriptPos;
                            baseExpr: TDataExpr; keyExpr: TTypedExpr;
                            arraySymbol : TAssociativeArraySymbol);
         destructor Destroy; override;

         function IsWritable : Boolean; override;

         function SameDataExpr(expr : TTypedExpr) : Boolean; override;

         procedure GetDataPtr(exec : TdwsExecution; var result : IDataContext); override;
         function  EvalAsInteger(exec : TdwsExecution) : Int64; override;
         function  EvalAsBoolean(exec : TdwsExecution) : Boolean; override;

         property BaseExpr : TDataExpr read FBaseExpr;
         property KeyExpr : TTypedExpr read FKeyExpr;
   end;

   // Associative array x[key] when key is a value
   TAssociativeArrayValueKeyGetExpr = class (TAssociativeArrayGetExpr)
      public
         function  EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   TAssociativeArraySetExpr = class (TNoResultExpr)
      protected
         FBaseExpr : TDataExpr;
         FKeyExpr : TTypedExpr;
         FValueExpr : TTypedExpr;

         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(const aScriptPos: TScriptPos; baseExpr: TDataExpr;
                            keyExpr, valueExpr: TTypedExpr);
         destructor Destroy; override;

         procedure EvalNoResult(exec : TdwsExecution); override;

         property BaseExpr : TDataExpr read FBaseExpr;
         property KeyExpr : TTypedExpr read FKeyExpr;
         property ValueExpr : TTypedExpr read FValueExpr;
   end;

   TAssociativeArrayContainsKeyExpr = class (TBooleanBinOpExpr)
      public
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   // Record expression: record.member
   TRecordExpr = class(TPosDataExpr)
      protected
         FBaseExpr : TDataExpr;
         FMemberOffset : Integer;
         FFieldSymbol : TFieldSymbol;

         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

         function GetIsConstant : Boolean; override;

      public
         constructor Create(const aScriptPos: TScriptPos; BaseExpr: TDataExpr;
                            fieldSymbol: TFieldSymbol);
         destructor Destroy; override;
         procedure Orphan(context : TdwsCompilerContext); override;

         procedure AssignExpr(exec : TdwsExecution; Expr: TTypedExpr); override;
         procedure AssignValueAsInteger(exec : TdwsExecution; const value : Int64); override;
         procedure AssignValueAsBoolean(exec : TdwsExecution; const value : Boolean); override;
         procedure AssignValueAsFloat(exec : TdwsExecution; const value : Double); override;
         procedure AssignValueAsString(exec : TdwsExecution; const value: String); override;
         procedure AssignValueAsScriptObj(exec : TdwsExecution; const value : IScriptObj); override;

         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
         function EvalAsFloat(exec : TdwsExecution) : Double; override;
         procedure EvalAsVariant(exec : TdwsExecution; var result : Variant); override;
         procedure EvalAsString(exec : TdwsExecution; var result : String); override;

         procedure GetDataPtr(exec : TdwsExecution; var result : IDataContext); override;

         function SameDataExpr(expr : TTypedExpr) : Boolean; override;

         function SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr; override;

         property BaseExpr : TDataExpr read FBaseExpr;
         property MemberOffset : Integer read FMemberOffset;
         property FieldSymbol : TFieldSymbol read FFieldSymbol;

         function IsWritable : Boolean; override;
   end;

   // Record expression: record.member when BaseExpr is a TVarExpr
   TRecordVarExpr = class(TRecordExpr)
      private
         FVarPlusMemberOffset : Integer;

      public
         constructor Create(const aScriptPos: TScriptPos; baseExpr: TVarExpr;
                            fieldSymbol : TFieldSymbol);

         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
         function EvalAsFloat(exec : TdwsExecution) : Double; override;
         procedure EvalAsVariant(exec : TdwsExecution; var result : Variant); override;
         procedure EvalAsString(exec : TdwsExecution; var result : String); override;

         procedure GetDataPtr(exec : TdwsExecution; var result : IDataContext); override;

         property VarPlusMemberOffset : Integer read FVarPlusMemberOffset write FVarPlusMemberOffset;
   end;

   TInitDataExpr = class sealed (TNoResultExpr)
      protected
         FExpr : TDataExpr;

         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos; Expr: TDataExpr);
         destructor Destroy; override;

         function  SpecializeProgramExpr(const context : ISpecializationContext) : TProgramExpr; override;

         procedure EvalNoResult(exec : TdwsExecution); override;

         property Expr : TDataExpr read FExpr;
   end;

   // dynamic anonymous record
   TDynamicRecordExpr = class(TPosDataExpr)
      private
         FAddr : Integer;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const aPos : TScriptPos;
                            recordTyp : TRecordSymbol);

         procedure EvalNoResult(exec : TdwsExecution); override;
         procedure GetDataPtr(exec : TdwsExecution; var result : IDataContext); override;

         property Addr : Integer read FAddr;
   end;

   // Field expression: obj.Field
   TFieldExpr = class(TPosDataExpr)
      protected
         FObjectExpr : TTypedExpr;
         FFieldSym : TFieldSymbol;

         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

         function GetScriptObj(exec : TdwsExecution) : IScriptObj; inline;

      public
         constructor Create(const aScriptPos: TScriptPos;
                            fieldSym : TFieldSymbol; objExpr: TTypedExpr);
         destructor Destroy; override;

         procedure AssignValueAsInteger(exec : TdwsExecution; const value : Int64); override;
         procedure AssignValueAsBoolean(exec : TdwsExecution; const value : Boolean); override;
         procedure AssignValueAsFloat(exec : TdwsExecution; const value : Double); override;
         procedure AssignValueAsString(exec : TdwsExecution; const value: String); override;
         procedure AssignValueAsScriptObj(exec : TdwsExecution; const value : IScriptObj); override;

         procedure EvalAsString(exec : TdwsExecution; var result : String); override;
         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
         function EvalAsFloat(exec : TdwsExecution) : Double; override;
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
         procedure EvalAsScriptObj(exec : TdwsExecution; var Result : IScriptObj); override;

         procedure GetDataPtr(exec : TdwsExecution; var result : IDataContext); override;

         function SameDataExpr(expr : TTypedExpr) : Boolean; override;

         property ObjectExpr : TTypedExpr read FObjectExpr;
         property FieldSym : TFieldSymbol read FFieldSym;
   end;

   // Field expression: obj.Field
   TFieldVarExpr = class sealed (TFieldExpr)
      protected
         function GetPIScriptObj(exec : TdwsExecution) : PIScriptObj; inline;

      public
         procedure AssignValueAsInteger(exec : TdwsExecution; const value : Int64); override;

         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
         function EvalAsFloat(exec : TdwsExecution) : Double; override;
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;

         procedure GetDataPtr(exec : TdwsExecution; var result : IDataContext); override;

         function SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr; override;
   end;

   TReadOnlyFieldExpr = class sealed (TFieldExpr)
      public
         constructor Create(const aScriptPos: TScriptPos;
                            fieldSym : TFieldSymbol; objExpr: TTypedExpr;
                            propertyType : TTypeSymbol);

         function IsWritable: Boolean; override;

         function SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr; override;
   end;

   // length of dynamic arrays
   TArrayLengthExpr = class (TUnaryOpIntExpr)
      private
         FDelta : Integer;
         FCapture : Boolean;
      public
         constructor Create(context : TdwsCompilerContext; const aScriptPos : TScriptPos; expr : TTypedExpr; captureExpr : Boolean); reintroduce; virtual;
         destructor Destroy; override;

         function SpecializeTypedExpr(const context : ISpecializationContext) : TTypedExpr; override;

         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
         property Delta : Integer read FDelta write FDelta;
   end;
   TArrayLengthExprClass = class of TArrayLengthExpr;

   // length of an open array
   TOpenArrayLengthExpr = class (TArrayLengthExpr)
      public
         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   // length of an associative array
   TAssociativeArrayLengthExpr = class(TUnaryOpIntExpr)
      public
         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   // left[right] String read access
   TStringArrayOpExpr = class(TStringBinOpExpr)
      private
         FScriptPos : TScriptPos;

      public
         constructor CreatePos(context : TdwsCompilerContext; const aScriptPos: TScriptPos; Left, Right: TTypedExpr);
         procedure EvalAsString(exec : TdwsExecution; var result : String); override;
         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
         function ScriptPos : TScriptPos; override;
   end;

   TStringLengthExpr = class(TUnaryOpIntExpr)
      public
         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   // returns a dynamic array
   TDynamicArrayDataExpr = class(TPosDataExpr)
      public
         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
         procedure GetDataPtr(exec : TdwsExecution; var result : IDataContext); override;
   end;

   // new array[length,...]
   TNewArrayExpr = class(TDynamicArrayDataExpr)
      private
         FLengthExprs : TTightList;
         FTyps : TTightList;

         function GetLengthExpr(idx : Integer) : TTypedExpr; inline;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const scriptPos: TScriptPos;
                            elementTyp : TTypeSymbol); overload;
         constructor Create(const scriptPos: TScriptPos; arrayTyp : TDynamicArraySymbol); overload;
         destructor Destroy; override;

         procedure EvalAsScriptDynArray(exec : TdwsExecution; var Result : IScriptDynArray); override;

         procedure AddLengthExpr(expr : TTypedExpr; indexTyp : TTypeSymbol);
         property LengthExpr[idx : Integer] : TTypedExpr read GetLengthExpr;
         property LengthExprCount : Integer read FLengthExprs.FCount;
   end;

   // Pseudo-method for dynamic and associative arrays
   TArrayPseudoMethodExpr = class(TNoResultExpr)
      private
         FBaseExpr : TTypedExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(const scriptPos: TScriptPos; aBase : TTypedExpr);
         destructor Destroy; override;

         property BaseExpr : TTypedExpr read FBaseExpr;
   end;

   // SetLength of dynamic array
   TArraySetLengthExpr = class(TArrayPseudoMethodExpr)
      private
         FLengthExpr : TTypedExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(const scriptPos: TScriptPos; aBase, aLength : TTypedExpr);
         destructor Destroy; override;
         procedure EvalNoResult(exec : TdwsExecution); override;

         property LengthExpr : TTypedExpr read FLengthExpr;
   end;

   // TypedExpr for dynamic array
   TArrayTypedExpr = class(TTypedExpr)
      private
         FBaseExpr : TTypedExpr;
         FScriptPos : TScriptPos;

      public
         constructor Create(context : TdwsCompilerContext; const scriptPos: TScriptPos;
                            aBaseExpr : TTypedExpr);
         destructor Destroy; override;

         function ScriptPos : TScriptPos; override;

         property BaseExpr : TTypedExpr read FBaseExpr;
   end;

   // TypedExpr for dynamic array that returns the array (for fluent-style)
   TArrayTypedFluentExpr = class(TArrayTypedExpr)
      public
         constructor Create(context : TdwsCompilerContext; const scriptPos: TScriptPos;
                            aBaseExpr : TTypedExpr);

         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // Swap two elements of a dynamic array
   TArraySwapExpr = class(TArrayTypedFluentExpr)
      private
         FIndex1Expr : TTypedExpr;
         FIndex2Expr : TTypedExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const scriptPos: TScriptPos;
                            aBase, aIndex1, aIndex2 : TTypedExpr);
         destructor Destroy; override;

         procedure EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray); override;

         property Index1Expr : TTypedExpr read FIndex1Expr;
         property Index2Expr : TTypedExpr read FIndex2Expr;
   end;

   // Sort a dynamic array
   TArraySortExpr = class(TArrayTypedFluentExpr)
      private
         FCompareExpr : TFuncPtrExpr;
         FLeft, FRight : TDataSymbol;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const scriptPos: TScriptPos;
                            aBase : TTypedExpr; aCompare : TFuncPtrExpr);
         destructor Destroy; override;

         procedure EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray); override;

         property CompareExpr : TFuncPtrExpr read FCompareExpr write FCompareExpr;
   end;

   // Sort a dynamic array (natural order)
   TArraySortNaturalExpr = class(TArrayTypedFluentExpr)
      public
         procedure SetCompareMethod(var qs : TQuickSort; dyn : TScriptDynamicValueArray); virtual;
         procedure EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray); override;
   end;

   TArraySortNaturalStringExpr = class(TArraySortNaturalExpr)
      public
         procedure SetCompareMethod(var qs : TQuickSort; {%H-}dyn : TScriptDynamicValueArray); override;
   end;

   TArraySortNaturalIntegerExpr = class(TArraySortNaturalExpr)
      public
         procedure SetCompareMethod(var qs : TQuickSort; {%H-}dyn : TScriptDynamicValueArray); override;
   end;

   TArraySortNaturalFloatExpr = class(TArraySortNaturalExpr)
      public
         procedure SetCompareMethod(var qs : TQuickSort; {%H-}dyn : TScriptDynamicValueArray); override;
   end;

   // Returns the storage to use for the next call, normal sequence is
   // - first call with number of items as parameter (<0 if unknown), will return storage for 1st item
   // - second call with n=0, after having stored the first item, returns storage for second item (can be same)
   // - etc
   {$IFDEF FPC}
   TArrayDataEnumeratorCallback = function(n : Integer) : PVariant;
   TArrayDataEnumeratorCallbackString = function(n : Integer) : PString;
   {$ELSE}
   TArrayDataEnumeratorCallback = reference to function(n : Integer) : PVariant;
   TArrayDataEnumeratorCallbackString = reference to function(n : Integer) : PString;
   {$ENDIF}

   // Map a dynamic array
   TArrayMapExpr = class sealed (TArrayTypedExpr)
      private
         FMapFuncExpr : TFuncPtrExpr;
         FItem : TDataSymbol;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

         procedure BaseAsCallback(exec : TdwsExecution; const initial, callback : TArrayDataEnumeratorCallback);

      public
         constructor Create(context : TdwsCompilerContext; const scriptPos: TScriptPos;
                            aBase : TTypedExpr; aMapFunc : TFuncPtrExpr);
         destructor Destroy; override;

         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
         procedure EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray); override;

         procedure EvalAsCallback(exec : TdwsExecution; const initial, callback : TArrayDataEnumeratorCallback);
         procedure EvalAsCallbackString(exec : TdwsExecution; const initial, callback : TArrayDataEnumeratorCallbackString);

         property MapFuncExpr : TFuncPtrExpr read FMapFuncExpr write FMapFuncExpr;
   end;

   // Filter a dynamic array
   TArrayFilterExpr = class(TArrayTypedExpr)
      private
         FFilterFuncExpr : TFuncPtrExpr;
         FItem : TDataSymbol;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const scriptPos: TScriptPos;
                            aBase : TTypedExpr; aFilterFunc : TFuncPtrExpr);
         destructor Destroy; override;

         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
         procedure EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray); override;

         property FilterFuncExpr : TFuncPtrExpr read FFilterFuncExpr write FFilterFuncExpr;
   end;

   // Reverse a dynamic array
   TArrayReverseExpr = class(TArrayTypedFluentExpr)
      public
         procedure EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray); override;
   end;

   // Add an item to a dynamic array
   TArrayAddExpr = class sealed (TArrayPseudoMethodExpr)
      private
         FArgs : TTightList;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

         function GetItemExpr(idx : Integer) : TTypedExpr;

         procedure DoEval(exec : TdwsExecution; var base : IScriptDynArray);

      public
         constructor Create(const scriptPos: TScriptPos;
                            aBase :  TTypedExpr; argExprs : TTypedExprList);
         destructor Destroy; override;
         procedure EvalNoResult(exec : TdwsExecution); override;

         procedure AddArg(expr : TTypedExpr);
         procedure ExtractArgs(destination : TArrayAddExpr);

         function SpecializeProgramExpr(const context : ISpecializationContext) : TProgramExpr; override;

         property ArgExpr[idx : Integer] : TTypedExpr read GetItemExpr;
         property ArgCount : Integer read FArgs.FCount;
   end;

   // base class for dynamic array expr that return a value
   TArrayDataExpr = class(TPosDataExpr)
      private
         FBaseExpr : TTypedExpr;
         FResultAddr : Integer;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

         function GetBaseDynArray(exec : TdwsExecution) : TScriptDynamicArray;

      public
         constructor Create(context : TdwsCompilerContext; const scriptPos: TScriptPos;
                            aBase :  TTypedExpr);
         destructor Destroy; override;

         procedure GetDataPtr(exec : TdwsExecution; var result : IDataContext); override;

         property BaseExpr : TTypedExpr read FBaseExpr write FBaseExpr;
   end;

   // Peek the last value of a dynamic array
   TArrayPeekExpr = class (TArrayDataExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
         function  SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr; override;
   end;

   // Pop the last value of a dynamic array
   TArrayPopExpr = class sealed (TArrayPeekExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
         function  SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr; override;
   end;

   // Delete one or N elements of a dynamic array
   TArrayDeleteExpr = class(TArrayPseudoMethodExpr)
      private
         FIndexExpr : TTypedExpr;
         FCountExpr : TTypedExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(const scriptPos: TScriptPos;
                            aBase, aIndex, aCount : TTypedExpr);
         destructor Destroy; override;
         procedure EvalNoResult(exec : TdwsExecution); override;

         property IndexExpr : TTypedExpr read FIndexExpr;
         property CountExpr : TTypedExpr read FCountExpr;
   end;

   // Shallow-copy of a subset of an array
   TArrayCopyExpr = class(TArrayTypedExpr)
      private
         FIndexExpr : TTypedExpr;
         FCountExpr : TTypedExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const scriptPos: TScriptPos;
                            aBase, aIndex, aCount : TTypedExpr);
         destructor Destroy; override;

         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
         procedure EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray); override;

         property IndexExpr : TTypedExpr read FIndexExpr;
         property CountExpr : TTypedExpr read FCountExpr;
   end;

   // Find element in a dynamic array (shallow comparison)
   TArrayIndexOfExpr = class(TArrayTypedExpr)
      private
         FItemExpr : TTypedExpr;
         FFromIndexExpr : TTypedExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                            aBase : TTypedExpr; aItem : TTypedExpr; aFromIndex : TTypedExpr); reintroduce; virtual;
         destructor Destroy; override;

         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;

         property ItemExpr : TTypedExpr read FItemExpr;
         property FromIndexExpr : TTypedExpr read FFromIndexExpr;
   end;

   TArrayIndexOfExprClass = class of TArrayIndexOfExpr;

   TDynamicArrayIndexOfMethod = function (exec : TdwsExecution; dyn : TScriptDynamicArray) : Integer of object;

   TDynamicArrayIndexOfExpr = class(TArrayIndexOfExpr)
      private
         FMethod : TDynamicArrayIndexOfMethod;

      protected
         function DoEvalValue(exec : TdwsExecution; dyn : TScriptDynamicArray) : Integer;
         function DoEvalString(exec : TdwsExecution; dyn : TScriptDynamicArray) : Integer;
         function DoEvalInteger(exec : TdwsExecution; dyn : TScriptDynamicArray) : Integer;
         function DoEvalFuncPtr(exec : TdwsExecution; dyn : TScriptDynamicArray) : Integer;
         function DoEvalData(exec : TdwsExecution; dyn : TScriptDynamicArray) : Integer;

      public
         constructor Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                            aBase : TTypedExpr; aItem : TTypedExpr; aFromIndex : TTypedExpr); override;

         function  EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   TStaticArrayIndexOfExpr = class(TArrayIndexOfExpr)
      private
         FForceZeroBased : Boolean;

      public
         function  EvalAsInteger(exec : TdwsExecution) : Int64; override;

         property ForceZeroBased : Boolean read FForceZeroBased write FForceZeroBased;
   end;

   // Remove an element in a dynamic array (shallow comparison)
   TArrayRemoveExpr = class(TDynamicArrayIndexOfExpr)
      public
         function  EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   // Insert an element at a given index of a dynamic array
   TArrayInsertExpr = class(TArrayPseudoMethodExpr)
      private
         FIndexExpr : TTypedExpr;
         FItemExpr : TTypedExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(const scriptPos: TScriptPos;
                            aBase, aIndex : TTypedExpr; aItem : TTypedExpr);
         destructor Destroy; override;
         procedure EvalNoResult(exec : TdwsExecution); override;

         property IndexExpr : TTypedExpr read FIndexExpr;
         property ItemExpr : TTypedExpr read FItemExpr;
   end;

   // Move an element from one index to another, shifting other items in the procees
   TArrayMoveExpr = class(TArrayPseudoMethodExpr)
      private
         FOriginIndexExpr : TTypedExpr;
         FDestinationIndexExpr : TTypedExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(const scriptPos: TScriptPos;
                            aBase, anOriginIndex, aDestinationIndex : TTypedExpr);
         destructor Destroy; override;
         procedure EvalNoResult(exec : TdwsExecution); override;

         property OriginIndexExpr : TTypedExpr read FOriginIndexExpr;
         property DestinationIndexExpr : TTypedExpr read FDestinationIndexExpr;
   end;

   // Concatenates two or more arrays
   TArrayConcatExpr = class(TDynamicArrayDataExpr)
      private
         FAddExpr : TArrayAddExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

         function GetArgs(index : Integer) : TTypedExpr; inline;

      public
         constructor Create(const scriptPos : TScriptPos; aTyp: TDynamicArraySymbol);
         destructor Destroy; override;

         procedure EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray); override;

         procedure AddArg(arg : TTypedExpr);

         property AddExpr : TArrayAddExpr read FAddExpr;
         property ArgExpr[index : Integer] : TTypedExpr read GetArgs;
         function ArgCount : Integer; inline;
   end;

   TAssociativeArrayClearExpr = class (TArrayPseudoMethodExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   TAssociativeArrayDeleteExpr = class (TTypedExpr)
      private
         FBaseExpr : TTypedExpr;
         FKeyExpr : TTypedExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; aBase, aKey : TTypedExpr);
         destructor Destroy; override;

         function  EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
         procedure EvalAsVariant(exec : TdwsExecution; var result : Variant); override; final;
         procedure EvalNoResult(exec : TdwsExecution); override; final;

         property BaseExpr : TTypedExpr read FBaseExpr;
         property KeyExpr : TTypedExpr read FKeyExpr;
   end;

   TAssociativeArrayKeysExpr = class (TUnaryOpExpr)
      public
         constructor Create(context : TdwsBaseSymbolsContext; const aScriptPos : TScriptPos; expr : TTypedExpr); override;

         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override; final;
         procedure EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray); override;
   end;

   TAssignedExpr = class(TUnaryOpBoolExpr)
   end;

   TAssignedInstanceExpr = class(TAssignedExpr)
   public
     function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   TAssignedInterfaceExpr = class(TAssignedExpr)
   public
     function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   TAssignedMetaClassExpr = class(TAssignedExpr)
   public
     function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   TAssignedFuncPtrExpr = class(TAssignedExpr)
   public
     function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   TOrdExpr = class(TUnaryOpIntExpr)
   public
     function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   TOrdIntExpr = class(TOrdExpr)
   public
     function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   TOrdBoolExpr = class(TOrdExpr)
      public
         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   TOrdStrExpr = class(TOrdExpr)
   public
     function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   // obj is TMyClass
   TIsOpExpr = class(TBooleanBinOpExpr)
      public
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   // obj left = obj right
   TObjCmpEqualExpr = class(TBooleanBinOpExpr)
      public
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   // obj left <> obj right
   TObjCmpNotEqualExpr = class(TBooleanBinOpExpr)
      public
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   // interface left = interface right
   TIntfCmpExpr = class(TBooleanBinOpExpr)
      public
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   // obj implements Interface
   TImplementsIntfOpExpr = class(TBooleanBinOpExpr)
      public
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   // class implements Interface
   TClassImplementsIntfOpExpr = class(TBooleanBinOpExpr)
      public
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   // -x
   TNegVariantExpr = class(TUnaryOpVariantExpr)
      procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
   end;
   TNegIntExpr = class (TUnaryOpIntExpr)
     function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;
   TNegFloatExpr = class (TUnaryOpFloatExpr)
     function EvalAsFloat(exec : TdwsExecution) : Double; override;
   end;

   // a + b
   TAddVariantExpr = class(TVariantBinOpExpr)
      procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
   end;
   TAddStrExpr = class sealed (TStringBinOpExpr)
      procedure EvalAsString(exec : TdwsExecution; var result : String); override;
      function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;
   TAddStrConstExpr = class sealed (TStringBinOpExpr)
      procedure EvalAsString(exec : TdwsExecution; var result : String); override;
   end;
   TAddIntExpr = class sealed (TIntegerBinOpExpr)
      function EvalAsInteger(exec : TdwsExecution) : Int64; override;
      function EvalAsFloat(exec : TdwsExecution) : Double; override;
   end;
   TAddFloatExpr = class sealed (TFloatBinOpExpr)
      function EvalAsFloat(exec : TdwsExecution) : Double; override;
      function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;

   // a - b
   TSubVariantExpr = class(TVariantBinOpExpr)
      procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
   end;
   TSubIntExpr = class sealed (TIntegerBinOpExpr)
     function EvalAsInteger(exec : TdwsExecution) : Int64; override;
     function EvalAsFloat(exec : TdwsExecution) : Double; override;
   end;
   TSubFloatExpr = class(TFloatBinOpExpr)
     function EvalAsFloat(exec : TdwsExecution) : Double; override;
   end;

   // a * b
   TMultVariantExpr = class(TVariantBinOpExpr)
      procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
   end;
   TMultIntExpr = class(TIntegerBinOpExpr)
      function EvalAsInteger(exec : TdwsExecution) : Int64; override;
      function EvalAsFloat(exec : TdwsExecution) : Double; override;
      function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;
   TMultIntPow2Expr = class(TUnaryOpIntExpr)
      private
         FShift : Integer;
      public
         function EvalAsInteger(exec : TdwsExecution) : Int64; override;

         property Shift : Integer read FShift;
   end;
   TMultFloatExpr = class(TFloatBinOpExpr)
      function EvalAsFloat(exec : TdwsExecution) : Double; override;
      function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;

   // Sqr ( a )
   TSqrIntExpr = class(TUnaryOpIntExpr)
     function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;
   TSqrFloatExpr = class(TUnaryOpFloatExpr)
     function EvalAsFloat(exec : TdwsExecution) : Double; override;
   end;

   // a / b
   TDivideExpr = class(TFloatBinOpExpr)
     function EvalAsFloat(exec : TdwsExecution) : Double; override;
     function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;

   // a mod b  (float)
   TModFloatExpr = class(TFloatBinOpExpr)
     function EvalAsFloat(exec : TdwsExecution) : Double; override;
   end;

   // a div b
   TDivExpr = class(TIntegerBinOpExpr)
      function EvalAsInteger(exec : TdwsExecution) : Int64; override;
      function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;
   // a div const b
   TDivConstExpr = class(TIntegerBinOpExpr)
      function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   // a mod b
   TModExpr = class(TIntegerBinOpExpr)
      function EvalAsInteger(exec : TdwsExecution) : Int64; override;
      function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;
   // a div const b
   TModConstExpr = class(TIntegerBinOpExpr)
      function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   // not bool a
   TNotBoolExpr = class(TUnaryOpBoolExpr)
      function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;
   // not int a
   TNotIntExpr = class(TUnaryOpIntExpr)
      function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;
   // not variant a
   TNotVariantExpr = class(TUnaryOpVariantExpr)
      procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
   end;

   // a and b
   TIntAndExpr = class(TIntegerBinOpExpr)
     function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;
   TBoolAndExpr = class(TBooleanBinOpExpr)
     function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
     function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;
   TVariantAndExpr = class(TVariantBinOpExpr)
      procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
   end;

   // a or b
   TIntOrExpr = class(TIntegerBinOpExpr)
     function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;
   TBoolOrExpr = class(TBooleanBinOpExpr)
     function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
     function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;
   TVariantOrExpr = class(TVariantBinOpExpr)
      procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
   end;

   // a xor b
   TIntXorExpr = class(TIntegerBinOpExpr)
      function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;
   TBoolXorExpr = class(TBooleanBinOpExpr)
      function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;
   TVariantXorExpr = class(TVariantBinOpExpr)
      procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
   end;

   // a implies b
   TBoolImpliesExpr = class(TBooleanBinOpExpr)
     function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   // a shift b
   TShiftExpr = class(TIntegerBinOpExpr)
      function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;

   // a shl b
   TShlExpr = class(TShiftExpr)
      function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   // a shr b
   TShrExpr = class(TShiftExpr)
      function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   // a sar b
   TSarExpr = class(TShiftExpr)
     function EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;

   // left in right (strings)
   TStringInStringExpr = class(TBooleanBinOpExpr)
      public
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
         function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;

   // var left in const right (strings)
   TVarStringInConstStringExpr = class(TBooleanBinOpExpr)
      public
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   // const left in var right (strings)
   TConstStringInVarStringExpr = class(TBooleanBinOpExpr)
      public
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   // left variant ?? right
   TCoalesceExpr = class(TBinaryOpExpr)
      public
         procedure EvalAsVariant(exec : TdwsExecution; var result : Variant); override;
   end;

   // left ?? right (strings)
   TCoalesceStrExpr = class(TStringBinOpExpr)
      public
         procedure EvalAsString(exec : TdwsExecution; var result : String); override;
         function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;

   // left ?? right (integers)
   TCoalesceIntExpr = class(TIntegerBinOpExpr)
      public
         function EvalAsInteger(exec : TdwsExecution) : Int64; override;
         function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;

   // left ?? right (floats)
   TCoalesceFloatExpr = class(TFloatBinOpExpr)
      public
         function EvalAsFloat(exec : TdwsExecution) : Double; override;
         function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;

   // left ?? right (class)
   TCoalesceClassExpr = class(TBinaryOpExpr)
      public
         constructor Create(context : TdwsCompilerContext; const aScriptPos : TScriptPos;
                            const anOp : TTokenType; aLeft, aRight : TTypedExpr); override;
         procedure EvalAsVariant(exec : TdwsExecution; var result : Variant); override;
         procedure EvalAsScriptObj(exec : TdwsExecution; var result : IScriptObj); override;
   end;

   // left ?? right (dyn array)
   TCoalesceDynArrayExpr = class(TBinaryOpExpr)
      public
         constructor Create(context : TdwsCompilerContext; const aScriptPos : TScriptPos;
                            const anOp : TTokenType; aLeft, aRight : TTypedExpr); override;
         procedure EvalAsVariant(exec : TdwsExecution; var result : Variant); override;
         procedure EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray); override;
   end;

   // Assert(condition, message);
   TAssertExpr = class(TNoResultExpr)
      protected
         FCond : TTypedExpr;
         FMessage : TTypedExpr;

         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos; condExpr, msgExpr : TTypedExpr);
         destructor Destroy; override;

         procedure EvalNoResult(exec : TdwsExecution); override;
         function  Optimize(context : TdwsCompilerContext) : TProgramExpr; override;

         property Cond : TTypedExpr read FCond;
         property Message : TTypedExpr read FMessage;
   end;

   // left := right;
   TAssignExpr = class(TNoResultExpr)
      protected
         FLeft : TDataExpr;
         FRight : TTypedExpr;

         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                            left : TDataExpr; right : TTypedExpr); virtual;
         destructor Destroy; override;
         procedure Orphan(context : TdwsCompilerContext); override;

         property Left : TDataExpr read FLeft;
         property Right : TTypedExpr read FRight write FRight;

         procedure EvalNoResult(exec : TdwsExecution); override;

         procedure TypeCheckAssign(context : TdwsCompilerContext); virtual;
         function  Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
         function  OptimizeConstAssignment(context : TdwsCompilerContext) : TNoResultExpr;

         function  SpecializeProgramExpr(const context : ISpecializationContext) : TProgramExpr; override;
   end;

   TAssignExprClass = class of TAssignExpr;

   // left := right; (class of)
   TAssignClassOfExpr = class(TAssignExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // left := right;
   TAssignDataExpr = class(TAssignExpr)
      protected
         FSize: Integer;

      public
         constructor Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                            left : TDataExpr; right : TTypedExpr); override;
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // left := right; (var, func)
   TAssignFuncExpr = class(TAssignExpr)
      public
         procedure TypeCheckAssign(context : TdwsCompilerContext); override;
         procedure EvalNoResult(exec : TdwsExecution); override;
         function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;

   // external left := right
   TAssignExternalExpr = class(TAssignExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
         function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;

   // left := [constant array];
   TAssignArrayConstantExpr = class(TAssignDataExpr)
      public
         constructor Create(context : TdwsCompilerContext; const aScriptPos : TScriptPos;
                            left : TDataExpr; right : TTypedExpr); override;
         procedure EvalNoResult(exec : TdwsExecution); override;
         procedure TypeCheckAssign(context : TdwsCompilerContext); override;
   end;

   // var left := const right;
   TAssignConstDataToVarExpr = class sealed (TAssignDataExpr)
      public
         constructor Create(context : TdwsCompilerContext; const aScriptPos : TScriptPos;
                            left : TDataExpr; right : TTypedExpr); override;
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // left := const right;
   TAssignConstExpr = class (TAssignExpr)
      public
         procedure TypeCheckAssign(context : TdwsCompilerContext); override;
         function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
         function RightValue : Variant; virtual; abstract;
   end;

   // left := const integer;
   TAssignConstToIntegerVarExpr = class sealed (TAssignConstExpr)
      protected
         FRight : Int64;

      public
         constructor CreateVal(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                               Left : TDataExpr; const rightValue : Int64);

         function  SpecializeProgramExpr(const context : ISpecializationContext) : TProgramExpr; override;

         procedure EvalNoResult(exec : TdwsExecution); override;
         function RightValue : Variant; override;

         property Right : Int64 read FRight write FRight;
   end;

   // left := const float;
   TAssignConstToFloatVarExpr = class(TAssignConstExpr)
      protected
         FRight : Double;
      public
         constructor CreateVal(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                               Left : TDataExpr; const rightValue : Double);
         procedure EvalNoResult(exec : TdwsExecution); override;
         function RightValue : Variant; override;
         property Right : Double read FRight write FRight;
   end;

   // left := const bool;
   TAssignConstToBoolVarExpr = class(TAssignConstExpr)
      protected
         FRight : Boolean;
      public
         constructor CreateVal(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                               Left : TDataExpr; const rightValue : Boolean);
         procedure EvalNoResult(exec : TdwsExecution); override;
         function RightValue : Variant; override;
         property Right : Boolean read FRight write FRight;
   end;

   // left := const String;
   TAssignConstToStringVarExpr = class(TAssignConstExpr)
      protected
         FRight : String;
      public
         constructor CreateVal(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                               Left : TDataExpr; const rightValue : String);
         procedure EvalNoResult(exec : TdwsExecution); override;
         function RightValue : Variant; override;
         property Right : String read FRight write FRight;
   end;

   // left := const Variant;
   TAssignConstToVariantVarExpr = class(TAssignConstExpr)
      protected
         FRight : Variant;
      public
         constructor CreateVal(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                               Left : TDataExpr; const rightValue : Variant);
         procedure EvalNoResult(exec : TdwsExecution); override;
         function RightValue : Variant; override;
         property Right : Variant read FRight write FRight;
   end;

   // left := nil (instance)
   TAssignNilToVarExpr = class(TAssignConstExpr)
      public
         constructor CreateVal(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                               left : TDataExpr);
         function RightValue : Variant; override;
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // left := nil (class)
   TAssignNilClassToVarExpr = class(TAssignNilToVarExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // left := nil (reset to default type)
   TAssignNilAsResetExpr = class(TAssignNilToVarExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // a := a op b
   TOpAssignExpr = class(TAssignExpr)
     function  Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;
   TOpAssignExprClass = class of TOpAssignExpr;

   // a += b
   TPlusAssignExpr = class(TOpAssignExpr)
     procedure EvalNoResult(exec : TdwsExecution); override;
   end;
   // a += b (int)
   TPlusAssignIntExpr = class(TPlusAssignExpr)
     procedure EvalNoResult(exec : TdwsExecution); override;
     function  Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;
   // a += b (float)
   TPlusAssignFloatExpr = class(TPlusAssignExpr)
     procedure EvalNoResult(exec : TdwsExecution); override;
   end;
   // a += b (String)
   TPlusAssignStrExpr = class(TPlusAssignExpr)
     procedure EvalNoResult(exec : TdwsExecution); override;
     function  Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;

   // a -= b
   TMinusAssignExpr = class(TOpAssignExpr)
     procedure EvalNoResult(exec : TdwsExecution); override;
   end;
   // a -= b (int)
   TMinusAssignIntExpr = class(TMinusAssignExpr)
     procedure EvalNoResult(exec : TdwsExecution); override;
     function  Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;
   // a -= b (float)
   TMinusAssignFloatExpr = class(TMinusAssignExpr)
     procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // a *= b
   TMultAssignExpr = class(TOpAssignExpr)
     procedure EvalNoResult(exec : TdwsExecution); override;
   end;
   // a *= b (int)
   TMultAssignIntExpr = class(TMultAssignExpr)
     procedure EvalNoResult(exec : TdwsExecution); override;
   end;
   // a *= b (float)
   TMultAssignFloatExpr = class(TMultAssignExpr)
     procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // a /= b
   TDivideAssignExpr = class(TOpAssignExpr)
     procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // a += b (int var)
   TIncIntVarExpr = class(TAssignExpr)
     procedure EvalNoResult(exec : TdwsExecution); override;
   end;
   // a -= b (int var)
   TDecIntVarExpr = class(TAssignExpr)
     procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // (int var) += (const inst)
   TIncIntVarWithConstExpr = class(TIncIntVarExpr)
     procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // Abs(v) (int)
   TAbsIntExpr = class(TUnaryOpIntExpr)
      function  EvalAsInteger(exec : TdwsExecution) : Int64; override;
   end;
   // Abs(v) (float)
   TAbsFloatExpr = class(TUnaryOpFloatExpr)
      function  EvalAsFloat(exec : TdwsExecution) : Double; override;
   end;
   // Abs(v) (variant)
   TAbsVariantExpr = class(TUnaryOpVariantExpr)
      procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
   end;

   // a += b (String var)
   TAppendStringVarExpr = class(TAssignExpr)
     procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // (String var) += (String const)
   TAppendConstStringVarExpr = class(TAssignExpr)
      private
         FAppendString : String;
      public
         constructor Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                            left : TDataExpr; right : TTypedExpr); override;
         procedure EvalNoResult(exec : TdwsExecution); override;
         property AppendString : String read FAppendString;
   end;

   // name of an enumeration element
   TEnumerationElementNameExpr = class (TUnaryOpStringExpr)
      protected
         function EvalElement(exec : TdwsExecution) : TElementSymbol;

      public
         constructor Create(context : TdwsBaseSymbolsContext; const aScriptPos : TScriptPos; expr : TTypedExpr); override;
         procedure EvalAsString(exec : TdwsExecution; var result : String); override;
   end;

   // qualified name of an enumeration element
   TEnumerationElementQualifiedNameExpr = class (TEnumerationElementNameExpr)
      public
         procedure EvalAsString(exec : TdwsExecution; var result : String); override;
   end;

   // statement; statement; statement;
   TBlockExpr = class sealed (TBlockExprBase)
      private
         FTable : TSymbolTable;

      protected
         procedure SpecializeTable(const context : ISpecializationContext; destination : TBlockExprBase); override;

      public
         constructor Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos);
         destructor Destroy; override;
         procedure Orphan(context : TdwsCompilerContext); override;

         procedure EvalNoResult(exec : TdwsExecution); override;
         function  Optimize(context : TdwsCompilerContext) : TProgramExpr; override;

         property  Table: TSymbolTable read FTable;
   end;

   // statement; statement; statement;
   TBlockExprNoTable = class sealed (TBlockExprBase)
      public
         procedure Orphan(context : TdwsCompilerContext); override;
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;
   TBlockExprNoTable2 = class sealed (TBlockExprBase)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;
   TBlockExprNoTable3 = class sealed (TBlockExprBase)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;
   TBlockExprNoTable4 = class sealed (TBlockExprBase)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // if FCond then FThen
   TIfThenExpr = class(TNoResultExpr)
      private
         FCond : TTypedExpr;
         FThen : TProgramExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                            condExpr : TTypedExpr; thenExpr : TProgramExpr);
         destructor Destroy; override;

         procedure EvalNoResult(exec : TdwsExecution); override;
         procedure Orphan(context : TdwsCompilerContext); override;
         function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
         function SpecializeProgramExpr(const context : ISpecializationContext) : TProgramExpr; override;
         procedure EnumerateSteppableExprs(const callback : TExprBaseProc); override;

         property CondExpr : TTypedExpr read FCond write FCond;
         property ThenExpr : TProgramExpr read FThen write FThen;
   end;

   // if FCond then FThen else FElse
   TIfThenElseExpr = class sealed (TIfThenExpr)
      private
         FElse : TProgramExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                            condExpr : TTypedExpr; thenExpr, elseExpr : TProgramExpr);
         destructor Destroy; override;

         procedure EvalNoResult(exec : TdwsExecution); override;
         procedure Orphan(context : TdwsCompilerContext); override;
         function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
         function SpecializeProgramExpr(const context : ISpecializationContext) : TProgramExpr; override;
         procedure EnumerateSteppableExprs(const callback : TExprBaseProc); override;

         property ElseExpr : TProgramExpr read FElse write FElse;
   end;

   // value := if FCond then FTrue else FFalse
   TIfThenElseValueExpr = class sealed (TDataExpr)
      private
         FScriptPos : TScriptPos;
         FCondExpr : TTypedExpr;
         FTrueExpr : TTypedExpr;
         FFalseExpr : TTypedExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

         function GetIsConstant : Boolean; override;

      public
         constructor Create(context : TdwsCompilerContext; const aPos : TScriptPos;
                            aTyp : TTypeSymbol;
                            condExpr, trueExpr, falseExpr : TTypedExpr);
         destructor Destroy; override;

         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
         function  EvalAsInteger(exec : TdwsExecution) : Int64; override;
         function  EvalAsFloat(exec : TdwsExecution) : Double; override;
         procedure EvalAsString(exec : TdwsExecution; var result : String); override;
         procedure GetDataPtr(exec : TdwsExecution; var result : IDataContext); override;

         function ScriptPos : TScriptPos; override;
         function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
         function SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr; override;

         property CondExpr : TTypedExpr read FCondExpr write FCondExpr;
         property TrueExpr : TTypedExpr read FTrueExpr write FTrueExpr;
         property FalseExpr : TTypedExpr read FFalseExpr write FFalseExpr;
   end;

   // Part of a case statement
   TCaseCondition = class (TRefCountedObject)
      private
         FTrueExpr : TProgramExpr;
         FScriptPos : TScriptPos;

         function IsOfTypeNumber(context : TdwsCompilerContext; typ : TTypeSymbol) : Boolean;

      public
         constructor Create(const aPos : TScriptPos);
         destructor Destroy; override;

         function GetSubExpr(i : Integer) : TExprBase; virtual; abstract;
         function GetSubExprCount : Integer; virtual; abstract;

         function IsTrue(exec : TdwsExecution; const value : Variant) : Boolean; virtual; abstract;
         function StringIsTrue(exec : TdwsExecution; const value : String) : Boolean; virtual; abstract;
         function IntegerIsTrue(const value : Int64) : Boolean; virtual; abstract;

         procedure TypeCheck(context : TdwsCompilerContext; typ : TTypeSymbol); virtual; abstract;
         function IsConstant : Boolean; virtual; abstract;
         function IsExpr(aClass : TClass) : Boolean; virtual; abstract;

         property ScriptPos : TScriptPos read FScriptPos;

         property TrueExpr : TProgramExpr read FTrueExpr write FTrueExpr;
   end;

   TCaseConditionClass = class of TCaseCondition;

   TCaseConditions = TObjectList<TCaseCondition>;

   TCaseConditionsHelper = class
      public
         class function CanOptimizeToTyped(const conditions : TTightList; exprClass : TClass) : Boolean;
   end;

   TCompareCaseCondition = class(TCaseCondition)
      private
         FCompareExpr : TTypedExpr;

      public
         constructor Create(const aPos : TScriptPos; compareExpr : TTypedExpr);
         destructor Destroy; override;

         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

         function IsTrue(exec : TdwsExecution; const value : Variant) : Boolean; override;
         function StringIsTrue(exec : TdwsExecution; const value : String) : Boolean; override;
         function IntegerIsTrue(const value : Int64) : Boolean; override;

         procedure TypeCheck(context : TdwsCompilerContext; typ : TTypeSymbol); override;
         function IsConstant : Boolean; override;
         function IsExpr(aClass : TClass) : Boolean; override;

         property CompareExpr : TTypedExpr read FCompareExpr;
   end;

   TCompareConstStringCaseCondition = class (TCaseCondition)
      private
         FValue : String;

      public
         constructor Create(const aPos : TScriptPos; const aValue : String);

         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

         function IsTrue(exec : TdwsExecution; const value : Variant) : Boolean; override;
         function StringIsTrue(exec : TdwsExecution; const value : String) : Boolean; override;
         function IntegerIsTrue(const value : Int64) : Boolean; override;

         procedure TypeCheck(context : TdwsCompilerContext; typ : TTypeSymbol); override;
         function IsConstant : Boolean; override;
         function IsExpr(aClass : TClass) : Boolean; override;

         property Value : String read FValue write FValue;
   end;

   TRangeCaseCondition = class(TCaseCondition)
      private
         FFromExpr : TTypedExpr;
         FToExpr : TTypedExpr;

      public
         constructor Create(const aPos : TScriptPos; fromExpr, toExpr : TTypedExpr);
         destructor Destroy; override;

         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

         function IsTrue(exec : TdwsExecution; const Value: Variant): Boolean; override;
         function StringIsTrue(exec : TdwsExecution; const value : String) : Boolean; override;
         function IntegerIsTrue(const value : Int64) : Boolean; override;

         procedure TypeCheck(context : TdwsCompilerContext; typ : TTypeSymbol); override;
         function IsConstant : Boolean; override;
         function IsExpr(aClass : TClass) : Boolean; override;

         property FromExpr : TTypedExpr read FFromExpr;
         property ToExpr : TTypedExpr read FToExpr;
   end;

   // case FValueExpr of {CaseConditions} else FElseExpr end;
   TCaseExpr = class(TNoResultExpr)
      private
         FCaseConditions : TTightList;
         FElseExpr : TProgramExpr;
         FValueExpr : TTypedExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         destructor Destroy; override;

         procedure AddCaseCondition(cond : TCaseCondition);

         procedure EvalNoResult(exec : TdwsExecution); override;

         function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
         procedure EnumerateSteppableExprs(const callback : TExprBaseProc); override;

         property CaseConditions : TTightList read FCaseConditions;
         property ValueExpr: TTypedExpr read FValueExpr write FValueExpr;
         property ElseExpr: TProgramExpr read FElseExpr write FElseExpr;
   end;

   TCaseStringExpr = class(TCaseExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   TCaseIntegerExpr = class(TCaseExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // val in [case conditions list]
   TInOpExpr = class(TTypedExpr)
      private
         FLeft : TTypedExpr;
         FCaseConditions : TTightList;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;
         function GetCaseConditions(idx : Integer) : TCaseCondition;

         function ConstantConditions : Boolean;

         function GetIsConstant : Boolean; override;

      public
         constructor Create(context : TdwsCompilerContext; Left : TTypedExpr);
         destructor Destroy; override;

         procedure EvalAsVariant(exec : TdwsExecution; var Result : Variant); override;
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
         procedure AddCaseCondition(cond : TCaseCondition);
         procedure Prepare; virtual;

         function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;

         property Left : TTypedExpr read FLeft;
         property CaseConditions[idx : Integer] : TCaseCondition read GetCaseConditions; default;
         property Count : Integer read FCaseConditions.FCount;
   end;

   TStringInOpExpr = class (TInOpExpr)
      public
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   TCharacterInOpExpr = class (TInOpExpr)
      private
         FMap : array of Boolean;
         FMapHigh : Integer;

      public
         class function AttemptCreate(context : TdwsCompilerContext; Left : TTypedExpr;
                                      const conditionsList : TTightList) : TCharacterInOpExpr; static;

         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   TIntegerInOpExpr = class (TInOpExpr)
      public
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   // special case of disjointed strings
   TStringInOpStaticSetExpr = class (TStringInOpExpr)
      private
         FSortedStrings : TUnicodeStringList;

      public
         destructor Destroy; override;

         procedure Prepare; override;

         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   // bitwise val in [case conditions list]
   TBitwiseInOpExpr = class(TUnaryOpBoolExpr)
      private
         FMask : Integer;

      public
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;

         property Mask : Integer read FMask write FMask;
   end;

   // for FVarExpr := FFromExpr to FToExpr do FDoExpr;
   TForExpr = class(TNoResultExpr)
      private
         FDoExpr : TProgramExpr;
         FFromExpr : TTypedExpr;
         FToExpr : TTypedExpr;
         FVarExpr : TIntVarExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(const aPos: TScriptPos); virtual;
         destructor Destroy; override;

         property DoExpr: TProgramExpr read FDoExpr write FDoExpr;
         property FromExpr: TTypedExpr read FFromExpr write FFromExpr;
         property ToExpr: TTypedExpr read FToExpr write FToExpr;
         property VarExpr: TIntVarExpr read FVarExpr write FVarExpr;

         function SpecializeProgramExpr(const context : ISpecializationContext) : TProgramExpr; override;
         procedure EnumerateSteppableExprs(const callback : TExprBaseProc); override;
   end;

   TForExprClass = class of TForExpr;

   TForUpwardExpr = class(TForExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   TForDownwardExpr = class(TForExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // for FVarExpr := FFromExpr to FToExpr step FStepExpr do FDoExpr;
   TForStepExpr = class(TForExpr)
      private
         FStepExpr : TTypedExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         destructor Destroy; override;

         function EvalStep(exec : TdwsExecution) : Int64;
         procedure RaiseForLoopStepShouldBeStrictlyPositive(exec : TdwsExecution; index : Int64);

         function SpecializeProgramExpr(const context : ISpecializationContext) : TProgramExpr; override;

         property StepExpr : TTypedExpr read FStepExpr write FStepExpr;
   end;

   TForSteprExprClass = class of TForStepExpr;

   TForUpwardStepExpr = class(TForStepExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   TForDownwardStepExpr = class(TForStepExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // for something in aString do ...;
   TForInStrExpr = class(TNoResultExpr)
      private
         FDoExpr : TProgramExpr;
         FInExpr : TTypedExpr;
         FVarExpr : TVarExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const aPos: TScriptPos;
                            aVarExpr : TVarExpr; aInExpr : TTypedExpr);
         destructor Destroy; override;

         procedure EnumerateSteppableExprs(const callback : TExprBaseProc); override;

         property DoExpr : TProgramExpr read FDoExpr write FDoExpr;
         property InExpr : TTypedExpr read FInExpr write FInExpr;
         property VarExpr : TVarExpr read FVarExpr write FVarExpr;
   end;

   // for charCode in aString do ...;
   TForCharCodeInStrExpr = class(TForInStrExpr)
      public
         constructor Create(context : TdwsCompilerContext; const aPos: TScriptPos;
                            aVarExpr : TIntVarExpr; aInExpr : TTypedExpr);

         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // for character in aString do ...;
   TForCharInStrExpr = class(TForInStrExpr)
      public
         constructor Create(context : TdwsCompilerContext; const aPos: TScriptPos;
                            aVarExpr : TStrVarExpr; aInExpr : TTypedExpr);

         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   // base class for while, repeat and infinite loops
   TLoopExpr = class(TNoResultExpr)
      private
         FCondExpr : TTypedExpr;
         FLoopExpr : TProgramExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         destructor Destroy; override;

         procedure EvalNoResult(exec : TdwsExecution); override;

         function SpecializeProgramExpr(const context : ISpecializationContext) : TProgramExpr; override;
         procedure EnumerateSteppableExprs(const callback : TExprBaseProc); override;

         property CondExpr : TTypedExpr read FCondExpr write FCondExpr;
         property LoopExpr : TProgramExpr read FLoopExpr write FLoopExpr;
   end;

   TLoopExprClass = class of TLoopExpr;

   // while FCondExpr do FLoopExpr
   TWhileExpr = class(TLoopExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
         function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;

   // repeat FLoopExpr while FCondExpr
   TRepeatExpr = class(TLoopExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
         function Optimize(context : TdwsCompilerContext) : TProgramExpr; override;
   end;

   TFlowControlExpr = class(TNoResultExpr)
      public
         function InterruptsFlow : Boolean; override;
   end;

   TBreakExpr = class(TFlowControlExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   TExitExpr = class(TFlowControlExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   TExitValueExpr = class(TExitExpr)
      private
         FAssignExpr : TAssignExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos; assignExpr : TAssignExpr);
         destructor Destroy; override;

         procedure EvalNoResult(exec : TdwsExecution); override;

         property AssignExpr : TAssignExpr read FAssignExpr;
   end;

   TContinueExpr = class(TFlowControlExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   TRaiseBaseExpr = class(TNoResultExpr)
   end;

   // raise TExceptionClass.Create;
   TRaiseExpr = class (TRaiseBaseExpr)
      private
         FExceptionExpr: TTypedExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const scriptPos: TScriptPos; ExceptionExpr: TTypedExpr);
         destructor Destroy; override;

         procedure EvalNoResult(exec : TdwsExecution); override;

         function InterruptsFlow : Boolean; override;
   end;

   TReraiseExpr = class(TRaiseBaseExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   TExceptionExpr = class(TNoResultExpr)
      private
         FTryExpr : TProgramExpr;
         FHandlerExpr : TProgramExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(tryExpr : TProgramExpr);
         destructor Destroy; override;

         procedure EnumerateSteppableExprs(const callback : TExprBaseProc); override;

         property TryExpr : TProgramExpr read FTryExpr write FTryExpr;
         property HandlerExpr : TProgramExpr read FHandlerExpr write FHandlerExpr;
   end;

   TExceptDoExpr = class;

   // try FTryExpr except {FDoExprs}; else FElseExpr end;
   TExceptExpr = class(TExceptionExpr)
      private
         FDoExprs : TTightList;
         FElseExpr : TProgramExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;
         function GetDoExpr(i : Integer) : TExceptDoExpr;

      public
         destructor Destroy; override;

         procedure EvalNoResult(exec : TdwsExecution); override;

         procedure AddDoExpr(expr : TExceptDoExpr);
         property DoExpr[i : Integer] : TExceptDoExpr read GetDoExpr;
         function DoExprCount : Integer;

         procedure EnumerateSteppableExprs(const callback : TExprBaseProc); override;

         property ElseExpr : TProgramExpr read FElseExpr write FElseExpr;
   end;

   // try..except on FExceptionVar: FExceptionVar.Typ do FDoBlockExpr; ... end;
   TExceptDoExpr = class(TNoResultExpr)
      private
         FExceptionTable : TSymbolTable;
         FDoBlockExpr : TProgramExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const aPos: TScriptPos);
         destructor Destroy; override;

         procedure EvalNoResult(exec : TdwsExecution); override;

         function ReferencesVariable(varSymbol : TDataSymbol) : Boolean; override;
         function ExceptionVar : TDataSymbol;

         property DoBlockExpr : TProgramExpr read FDoBlockExpr write FDoBlockExpr;
         property ExceptionTable : TSymbolTable read FExceptionTable;
   end;

   // try FTryExpr finally FHandlerExpr end;
   TFinallyExpr = class(TExceptionExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   TStringArraySetExpr = class(TNoResultExpr)
      private
         FStringExpr: TDataExpr;
         FIndexExpr: TTypedExpr;
         FValueExpr: TTypedExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos; StringExpr : TDataExpr; IndexExpr, ValueExpr: TTypedExpr);
         destructor Destroy; override;

         procedure EvalNoResult(exec : TdwsExecution); override;

         property StringExpr : TDataExpr read FStringExpr;
         property IndexExpr : TTypedExpr read FIndexExpr;
         property ValueExpr : TTypedExpr read FValueExpr;
   end;

   TVarStringArraySetExpr = class (TStringArraySetExpr)
      protected
         function EvalValueAsWideChar(exec : TdwsExecution) : WideChar; virtual;

      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   TVarStringArraySetChrExpr = class (TVarStringArraySetExpr)
      protected
         function EvalValueAsWideChar(exec : TdwsExecution) : WideChar; override;
   end;

   TSpecialUnaryBoolExpr = class(TUnaryOpBoolExpr)
      protected
         function GetIsConstant : Boolean; override;
   end;

   TConditionalDefinedExpr = class(TSpecialUnaryBoolExpr)
      public
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   TDefinedExpr = class(TSpecialUnaryBoolExpr)
      public
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
   end;

   TDeclaredExpr = class(TSpecialUnaryBoolExpr)
      public
         function EvalAsBoolean(exec : TdwsExecution) : Boolean; override;
         class function FindSymbol(symbolTable : TSymbolTable; const name : String) : TSymbol; static;
   end;

   TDebugBreakExpr = class(TNoResultExpr)
      public
         procedure EvalNoResult(exec : TdwsExecution); override;
   end;

   TSwapExpr = class(TNoResultExpr)
      private
         FArg0 : TDataExpr;
         FArg1 : TDataExpr;

      protected
         function GetSubExpr(i : Integer) : TExprBase; override;
         function GetSubExprCount : Integer; override;

      public
         constructor Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                            expr0, expr1 : TDataExpr);
         destructor Destroy; override;

         procedure EvalNoResult(exec : TdwsExecution); override;

         property Arg0 : TDataExpr read FArg0;
         property Arg1 : TDataExpr read FArg1;
   end;

   EClassCast = class (EScriptError) end;

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

uses
   dwsStringFunctions, dwsExternalSymbols, dwsSpecializationContext,
   dwsArrayElementContext, dwsCompilerUtils;

type
   // this needs to be in a helper (or more precisely implemented at the top of this unit)
   // otherwise inlining won't work
   TBoundsHelper = class helper for TProgramExpr
      procedure BoundsCheck(exec : TdwsExecution; aLength, index : Integer); inline;
      procedure BoundsCheckFailed(exec : TdwsExecution; index : Integer);
   end;

// BoundsCheck
//
procedure TBoundsHelper.BoundsCheck(exec : TdwsExecution; aLength, index : Integer);
begin
   if Cardinal(index)>=Cardinal(aLength) then
      BoundsCheckFailed(exec, index);
end;

// BoundsCheckFailed
//
procedure TBoundsHelper.BoundsCheckFailed(exec : TdwsExecution; index : Integer);
begin
   if index<0 then
      RaiseLowerExceeded(exec, index)
   else RaiseUpperExceeded(exec, index);
end;

// ------------------
// ------------------ TVarExpr ------------------
// ------------------

// Create
//
constructor TVarExpr.Create(dataSym : TDataSymbol);
begin
   inherited Create(dataSym.Typ);
   FStackAddr:=dataSym.StackAddr;
   FDataSym:=dataSym;
end;

// CreateTyped
//
class function TVarExpr.CreateTyped(context : TdwsCompilerContext; dataSym : TDataSymbol) : TVarExpr;
var
   typ : TTypeSymbol;
begin
   typ:=dataSym.Typ;
   if typ.IsOfType(context.TypInteger) then
      Result:=TIntVarExpr.Create(dataSym)
   else if typ.IsOfType(context.TypFloat) then
      Result:=TFloatVarExpr.Create(dataSym)
   else if typ.IsOfType(context.TypString) then
      Result:=TStrVarExpr.Create(dataSym)
   else if typ.IsOfType(context.TypBoolean) then
      Result:=TBoolVarExpr.Create(dataSym)
   else if dataSym.ClassType=TSelfSymbol then
      if (typ is TClassSymbol) then
         Result:=TSelfObjectVarExpr.Create(dataSym)
      else Result:=TSelfVarExpr.Create(dataSym)
   else if (typ is TClassSymbol) or (typ is TDynamicArraySymbol) then
      Result:=TObjectVarExpr.Create(dataSym)
   else if typ.Size=1 then
      Result:=TBaseTypeVarExpr.Create(dataSym)
   else Result:=TVarExpr.Create(dataSym);
end;

// Orphan
//
procedure TVarExpr.Orphan(context : TdwsCompilerContext);
begin
   DecRefCount;
end;

// EvalAsVariant
//
procedure TVarExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
begin
   DataPtr[exec].EvalAsVariant(0, Result);
end;

// ReferencesVariable
//
function TVarExpr.ReferencesVariable(varSymbol : TDataSymbol) : Boolean;
begin
   Result:=(FDataSym=varSymbol);
end;

// DataSymbol
//
function TVarExpr.DataSymbol : TDataSymbol;
begin
   Result:=FDataSym;
end;

// SpecializeDataExpr
//
function TVarExpr.SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr;
var
   specializedDataSym : TDataSymbol;
begin
   specializedDataSym := context.SpecializeDataSymbol(FDataSym);
   Result := TVarExpr.CreateTyped(CompilerContextFromSpecialization(context),
                                  specializedDataSym);
end;

// SameDataExpr
//
function TVarExpr.SameDataExpr(expr : TTypedExpr) : Boolean;
begin
   Result:=(ClassType=expr.ClassType) and (DataSym=TVarExpr(expr).DataSym);
end;

// GetDataPtr
//
procedure TVarExpr.GetDataPtr(exec : TdwsExecution; var result : IDataContext);
begin
   exec.Stack.InitDataPtr(Result, FStackAddr);
end;

// GetRelativeDataPtr
//
procedure TVarExpr.GetRelativeDataPtr(exec : TdwsExecution; var result : IDataContext);
begin
   exec.Stack.InitRelativeDataPtr(exec.GetStackPData, Result, FStackAddr);
end;

// IsWritable
//
function TVarExpr.IsWritable : Boolean;
begin
   Result := FDataSym.IsWritable;
end;

// AssignDataExpr
//
procedure TVarExpr.AssignDataExpr(exec : TdwsExecution; DataExpr: TDataExpr);
begin
   DataPtr[exec].WriteData(DataExpr.DataPtr[exec], Typ.Size);
end;

// AssignExpr
//
procedure TVarExpr.AssignExpr(exec : TdwsExecution; Expr: TTypedExpr);
var
   buf : Variant;
begin
   Expr.EvalAsVariant(exec, buf);
   DataPtr[exec][0] := buf;
end;

// AssignValue
//
procedure TVarExpr.AssignValue(exec : TdwsExecution; const Value: Variant);
begin
   DataPtr[exec][0]:=Value;
end;

// AssignValueAsInteger
//
procedure TVarExpr.AssignValueAsInteger(exec : TdwsExecution; const Value: Int64);
begin
   DataPtr[exec].AsInteger[0]:=Value;
end;

// AssignValueAsBoolean
//
procedure TVarExpr.AssignValueAsBoolean(exec : TdwsExecution; const value : Boolean);
begin
   DataPtr[exec].AsBoolean[0]:=Value;
end;

// AssignValueAsFloat
//
procedure TVarExpr.AssignValueAsFloat(exec : TdwsExecution; const Value: Double);
begin
   DataPtr[exec].AsFloat[0]:=Value;
end;

// AssignValueAsString
//
procedure TVarExpr.AssignValueAsString(exec : TdwsExecution; const Value: String);
begin
   DataPtr[exec].AsString[0]:=Value;
end;

// AssignValueAsScriptObj
//
procedure TVarExpr.AssignValueAsScriptObj(exec : TdwsExecution; const value : IScriptObj);
begin
   DataPtr[exec].AsInterface[0]:=Value;
end;

// ------------------
// ------------------ TBaseTypeVarExpr ------------------
// ------------------

// EvalAsVariant
//
procedure TBaseTypeVarExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
begin
   exec.Stack.ReadValue(exec.Stack.BasePointer + FStackAddr, Result);
end;

// EvalAsInterface
//
procedure TBaseTypeVarExpr.EvalAsInterface(exec : TdwsExecution; var result : IUnknown);
begin
   exec.Stack.ReadInterfaceValue(exec.Stack.BasePointer + FStackAddr, Result);
end;

// ------------------
// ------------------ TIntVarExpr ------------------
// ------------------

// AssignExpr
//
procedure TIntVarExpr.AssignExpr(exec : TdwsExecution; Expr: TTypedExpr);
begin
   exec.Stack.WriteIntValue_BaseRelative(FStackAddr, Expr.EvalAsInteger(exec));
end;

// AssignValue
//
procedure TIntVarExpr.AssignValue(exec : TdwsExecution; const value: Variant);
begin
   AssignValueAsInteger(exec, value);
end;

// AssignValueAsInteger
//
procedure TIntVarExpr.AssignValueAsInteger(exec : TdwsExecution; const value: Int64);
begin
   exec.Stack.WriteIntValue_BaseRelative(FStackAddr, value);
end;

// IncValue
//
procedure TIntVarExpr.IncValue(exec : TdwsExecution; const value: Int64);
begin
   exec.Stack.IncIntValue_BaseRelative(FStackAddr, value);
end;

// EvalAsInteger
//
function TIntVarExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=exec.Stack.ReadIntValue_BaseRelative(FStackAddr);
end;

// EvalAsFloat
//
function TIntVarExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   Result:=exec.Stack.ReadIntAsFloatValue_BaseRelative(FStackAddr);
end;

// EvalAsPInteger
//
function TIntVarExpr.EvalAsPInteger(exec : TdwsExecution) : PInt64;
begin
   Result:=exec.Stack.PointerToIntValue(exec.Stack.BasePointer+FStackAddr);
end;

// ------------------
// ------------------ TFloatVarExpr ------------------
// ------------------

// AssignExpr
//
procedure TFloatVarExpr.AssignExpr(exec : TdwsExecution; Expr: TTypedExpr);
begin
   exec.Stack.WriteFloatValue_BaseRelative(FStackAddr, Expr.EvalAsFloat(exec));
end;

// AssignValue
//
procedure TFloatVarExpr.AssignValue(exec : TdwsExecution; const value: Variant);
begin
   AssignValueAsFloat(exec, value);
end;

// AssignValueAsFloat
//
procedure TFloatVarExpr.AssignValueAsFloat(exec : TdwsExecution; const value: Double);
begin
   exec.Stack.WriteFloatValue_BaseRelative(FStackAddr, value);
end;

// EvalAsFloat
//
{$if Defined(WIN32_ASM)}
type
   TdwsExecutionCracker = class(TdwsExecution);
{$ifend}
function TFloatVarExpr.EvalAsFloat(exec : TdwsExecution) : Double;
{$if Defined(WIN32_ASM)}
asm
   lea   ecx, [edx].TdwsExecutionCracker.FStack
   mov   edx, [eax].FStackAddr
   mov   eax, ecx
   call  TStackMixIn.PointerToFloatValue_BaseRelative;
   fld   qword [eax]
{$else}
begin
   Result:=exec.Stack.PointerToFloatValue_BaseRelative(FStackAddr)^;
{$ifend}
end;

// ------------------
// ------------------ TStrVarExpr ------------------
// ------------------

// AssignExpr
//
procedure TStrVarExpr.AssignExpr(exec : TdwsExecution; Expr: TTypedExpr);
var
   buf : String;
begin
   Expr.EvalAsString(exec, buf);
   exec.Stack.WriteStrValue(exec.Stack.BasePointer + FStackAddr, buf);
end;

// AssignValue
//
procedure TStrVarExpr.AssignValue(exec : TdwsExecution; const value: Variant);
begin
   AssignValueAsString(exec, value);
end;

// AssignValueAsString
//
procedure TStrVarExpr.AssignValueAsString(exec : TdwsExecution; const value: String);
begin
   exec.Stack.WriteStrValue(exec.Stack.BasePointer + FStackAddr, value);
end;

// AssignValueAsUnicodeString
//
procedure TStrVarExpr.AssignValueAsUnicodeString(exec : TdwsExecution; const Value: UnicodeString);
begin
   AssignValueAsString(exec, String(value));
end;

// AssignValueAsWideChar
//
procedure TStrVarExpr.AssignValueAsWideChar(exec : TdwsExecution; aChar : WideChar);
var
   pstr : PString;
begin
   pstr := exec.Stack.PointerToStringValue_BaseRelative(FStackAddr);
   {$ifdef FPC}
   CodePointToString(Ord(aChar), pstr^);
   {$else}
   if Length(pstr^)=1 then
      pstr^[1]:=aChar
   else pstr^:=aChar;
   {$endif}
end;

// SetChar
//
function TStrVarExpr.SetChar(exec : TdwsExecution; index : Integer; c : WideChar) : Boolean;
begin
   Result:=exec.Stack.SetStrChar(exec.Stack.BasePointer + FStackAddr, index, c);
end;

// EvalAsString
//
procedure TStrVarExpr.EvalAsString(exec : TdwsExecution; var result : String);
begin
   exec.Stack.ReadStrValue(exec.Stack.BasePointer + FStackAddr, Result);
end;

// Append
//
procedure TStrVarExpr.Append(exec : TdwsExecution; const value : String);
begin
   exec.Stack.AppendStringValue_BaseRelative(FStackAddr, value);
end;

// EvalAsPString
//
function TStrVarExpr.EvalAsPString(exec : TdwsExecution) : PString;
begin
   Result:=exec.Stack.PointerToStringValue_BaseRelative(FStackAddr);
end;

// ------------------
// ------------------ TBoolVarExpr ------------------
// ------------------

// AssignExpr
//
procedure TBoolVarExpr.AssignExpr(exec : TdwsExecution; Expr: TTypedExpr);
begin
   exec.Stack.WriteBoolValue(exec.Stack.BasePointer + FStackAddr, Expr.EvalAsBoolean(exec));
end;

// AssignValue
//
procedure TBoolVarExpr.AssignValue(exec : TdwsExecution; const value: Variant);
begin
   AssignValueAsBoolean(exec, value);
end;

// AssignValueAsBoolean
//
procedure TBoolVarExpr.AssignValueAsBoolean(exec : TdwsExecution; const value : Boolean);
begin
   exec.Stack.WriteBoolValue(exec.Stack.BasePointer + FStackAddr, value);
end;

function TBoolVarExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
begin
   Result:=exec.Stack.ReadBoolValue(exec.Stack.BasePointer + FStackAddr);
end;

// EvalAsInteger
//
function TBoolVarExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=Int64(exec.Stack.ReadBoolValue(exec.Stack.BasePointer + FStackAddr));
end;

// ------------------
// ------------------ TObjectVarExpr ------------------
// ------------------

// AssignExpr
//
procedure TObjectVarExpr.AssignExpr(exec : TdwsExecution; Expr: TTypedExpr);
var
   buf : Variant;
begin
   Expr.EvalAsVariant(exec, buf);
   VarCopySafe(exec.Stack.Data[exec.Stack.BasePointer+FStackAddr], buf);
end;

// EvalAsScriptObj
//
procedure TObjectVarExpr.EvalAsScriptObj(exec : TdwsExecution; var Result : IScriptObj);
type
   PUnknown = ^IUnknown;
begin
   exec.Stack.ReadInterfaceValue(exec.Stack.BasePointer + FStackAddr, PUnknown(@Result)^);
end;

// EvalAsScriptDynArray
//
procedure TObjectVarExpr.EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray);
type
   PUnknown = ^IUnknown;
begin
   exec.Stack.ReadInterfaceValue(exec.Stack.BasePointer + FStackAddr, PUnknown(@Result)^);
end;

// ------------------
// ------------------ TSelfVarExpr ------------------
// ------------------

// IsWritable
//
function TSelfVarExpr.IsWritable : Boolean;
begin
   Result:=False;
end;

// ------------------
// ------------------ TSelfObjectVarExpr ------------------
// ------------------

// IsWritable
//
function TSelfObjectVarExpr.IsWritable : Boolean;
begin
   Result:=False;
end;

// ------------------
// ------------------ TVarParentExpr ------------------
// ------------------

// Create
//
constructor TVarParentExpr.Create(const aScriptPos: TScriptPos; dataSym : TDataSymbol);
begin
   inherited Create(dataSym);
   FLevel := dataSym.Level;
   FScriptPos := aScriptPos;
end;

// GetDataPtr
//
procedure TVarParentExpr.GetDataPtr(exec : TdwsExecution; var result : IDataContext);
begin
   exec.DataContext_CreateLevel(FLevel, FStackAddr, Result);
end;

// GetRelativeDataPtr
//
procedure TVarParentExpr.GetRelativeDataPtr(exec : TdwsExecution; var result : IDataContext);
begin
   exec.Stack.InitRelativeDataPtrLevel(exec.GetStackPData, result, FLevel, FStackAddr);
end;

// EvalAsVariant
//
procedure TVarParentExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
begin
   VarCopySafe(Result, exec.Stack.Data[exec.Stack.GetSavedBp(FLevel)+FStackAddr]);
end;

// EvalAsInteger
//
function TVarParentExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=exec.Stack.Data[exec.Stack.GetSavedBp(FLevel)+FStackAddr];
end;

// EvalAsFloat
//
function TVarParentExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   Result:=exec.Stack.Data[exec.Stack.GetSavedBp(FLevel)+FStackAddr];
end;

// ScriptPos
//
function TVarParentExpr.ScriptPos : TScriptPos;
begin
   Result := FScriptPos;
end;

// ------------------
// ------------------ TByRefParamExpr ------------------
// ------------------

// CreateFromVarExpr
//
constructor TByRefParamExpr.CreateFromVarExpr(expr : TVarExpr);
begin
   FTyp:=expr.Typ;
   FStackAddr:=expr.FStackAddr;
   FDataSym:=expr.DataSym;
end;

// GetVarParamDataPointer
//
function TByRefParamExpr.GetVarParamDataAsPointer(exec : TdwsExecution) : Pointer;
begin
   Result:=Pointer(exec.Stack.PointerToInterfaceValue_BaseRelative(FStackAddr)^);
end;

// GetVarParamData
//
procedure TByRefParamExpr.GetVarParamData(exec : TdwsExecution; var result : IDataContext);
begin
   result:=IDataContext(GetVarParamDataAsPointer(exec));
end;

// GetVarParamEval
//
function TByRefParamExpr.GetVarParamEval(exec : TdwsExecution) : PVariant;
begin
   Result:=IDataContext(GetVarParamDataAsPointer(exec)).AsPVariant(0);
end;

// GetDataPtr
//
procedure TByRefParamExpr.GetDataPtr(exec : TdwsExecution; var result : IDataContext);
begin
   Result:=IDataContext(GetVarParamDataAsPointer(exec));
end;

// GetRelativeDataPtr
//
procedure TByRefParamExpr.GetRelativeDataPtr(exec : TdwsExecution; var result : IDataContext);
begin
   Result:=IDataContext(GetVarParamDataAsPointer(exec));
end;

// AssignValue
//
procedure TByRefParamExpr.AssignValue(exec : TdwsExecution; const value : Variant);
begin
   DataPtr[exec][0]:=value;
end;

// AssignValueAsInteger
//
procedure TByRefParamExpr.AssignValueAsInteger(exec : TdwsExecution; const value : Int64);
begin
   IDataContext(GetVarParamDataAsPointer(exec)).AsInteger[0]:=value;
end;

// AssignValueAsBoolean
//
procedure TByRefParamExpr.AssignValueAsBoolean(exec : TdwsExecution; const value : Boolean);
begin
   IDataContext(GetVarParamDataAsPointer(exec)).AsBoolean[0]:=value;
end;

// AssignValueAsFloat
//
procedure TByRefParamExpr.AssignValueAsFloat(exec : TdwsExecution; const value : Double);
begin
   IDataContext(GetVarParamDataAsPointer(exec)).AsFloat[0]:=value;
end;

// AssignValueAsString
//
procedure TByRefParamExpr.AssignValueAsString(exec : TdwsExecution; const value : String);
begin
   IDataContext(GetVarParamDataAsPointer(exec)).AsString[0]:=value;
end;

// AssignValueAsScriptObj
//
procedure TByRefParamExpr.AssignValueAsScriptObj(exec : TdwsExecution; const value : IScriptObj);
begin
   IDataContext(GetVarParamDataAsPointer(exec)).AsInterface[0]:=value;
end;

// AssignExpr
//
procedure TByRefParamExpr.AssignExpr(exec : TdwsExecution; expr : TTypedExpr);
var
   v : PVariant;
begin
   v:=GetVarParamEval(exec);
   Expr.EvalAsVariant(exec, v^);
end;

// AssignDataExpr
//
procedure TByRefParamExpr.AssignDataExpr(exec : TdwsExecution; dataExpr: TDataExpr);
begin
   DataPtr[exec].WriteData(dataExpr.DataPtr[exec], Typ.Size);
end;

// EvalAsVariant
//
procedure TByRefParamExpr.EvalAsVariant(exec : TdwsExecution; var result : Variant);
begin
   VarCopySafe(Result, GetVarParamEval(exec)^);
end;

// EvalAsInterface
//
procedure TByRefParamExpr.EvalAsInterface(exec : TdwsExecution; var result : IUnknown);
begin
   IDataContext(GetVarParamDataAsPointer(exec)).EvalAsInterface(0, result);
end;

// EvalAsFloat
//
function TByRefParamExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   Result:=IDataContext(GetVarParamDataAsPointer(exec)).AsFloat[0];
end;

// SpecializeDataExpr
//
function TByRefParamExpr.SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr;
begin
   context.AddCompilerError(ClassName + '  specialization unsupported yet');
   Result := nil;
end;

// ------------------
// ------------------ TVarParamExpr ------------------
// ------------------

// SpecializeDataExpr
//
function TVarParamExpr.SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr;
begin
   Result := TVarParamExpr.Create(context.SpecializeDataSymbol(DataSymbol));
end;

// ------------------
// ------------------ TConstParamExpr ------------------
// ------------------

// IsWritable
//
function TConstParamExpr.IsWritable : Boolean;
begin
   Result:=False;
end;

// SpecializeDataExpr
//
function TConstParamExpr.SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr;
begin
   Result := TConstParamExpr.Create(context.SpecializeDataSymbol(DataSymbol));
end;

// ------------------
// ------------------ TByRefParentParamExpr ------------------
// ------------------

// Create
//
constructor TByRefParentParamExpr.Create(dataSym : TDataSymbol);
begin
   inherited;
   FLevel := dataSym.Level;
   dataSym.UsedBySubLevel := True;
end;

// GetDataPtr
//
procedure TByRefParentParamExpr.GetDataPtr(exec : TdwsExecution; var result : IDataContext);
begin
   Result := IDataContext(IUnknown(exec.Stack.Data[exec.Stack.GetSavedBp(FLevel) + FStackAddr]));
end;

// AssignExpr
//
procedure TByRefParentParamExpr.AssignExpr(exec : TdwsExecution; Expr: TTypedExpr);
begin
   expr.EvalAsVariant(exec, DataPtr[exec].AsPVariant(0)^);
end;

// EvalAsVariant
//
procedure TByRefParentParamExpr.EvalAsVariant(exec : TdwsExecution; var result : Variant);
begin
   VarCopySafe(Result, DataPtr[exec].AsVariant[0]);
end;

// EvalAsInterface
//
procedure TByRefParentParamExpr.EvalAsInterface(exec : TdwsExecution; var result : IUnknown);
begin
   result := DataPtr[exec].AsInterface[0];
end;

// EvalAsFloat
//
function TByRefParentParamExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   Result := DataPtr[exec].AsFloat[0];
end;

// EvalAsInteger
//
function TByRefParentParamExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result := DataPtr[exec].AsInteger[0];
end;

// ------------------
// ------------------ TConstParamParentExpr ------------------
// ------------------

// IsWritable
//
function TConstParamParentExpr.IsWritable : Boolean;
begin
   Result:=False;
end;

// ------------------
// ------------------ TArrayTypedExpr ------------------
// ------------------

// Create
//
constructor TArrayTypedExpr.Create(context : TdwsCompilerContext; const scriptPos: TScriptPos;
                                   aBaseExpr : TTypedExpr);
begin
   FScriptPos:=scriptPos;
   FBaseExpr:=aBaseExpr;
end;

// Destroy
//
destructor TArrayTypedExpr.Destroy;
begin
   inherited;
   FBaseExpr.Free;
end;

// ScriptPos
//
function TArrayTypedExpr.ScriptPos : TScriptPos;
begin
   Result:=FScriptPos;
end;

// ------------------
// ------------------ TArrayTypedFluentExpr ------------------
// ------------------

// Create
//
constructor TArrayTypedFluentExpr.Create(context : TdwsCompilerContext; const scriptPos: TScriptPos;
                                         aBaseExpr : TTypedExpr);
begin
   inherited Create(context, scriptPos, aBaseExpr);
   Typ := aBaseExpr.Typ;
end;

// EvalAsVariant
//
procedure TArrayTypedFluentExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   dyn : IScriptDynArray;
begin
   EvalAsScriptDynArray(exec, dyn);
   Result := dyn;
end;

// EvalNoResult
//
procedure TArrayTypedFluentExpr.EvalNoResult(exec : TdwsExecution);
var
   dyn : IScriptDynArray;
begin
   EvalAsScriptDynArray(exec, dyn);
end;

// ------------------
// ------------------ TDynamicArrayDataExpr ------------------
// ------------------

// EvalAsVariant
//
procedure TDynamicArrayDataExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   dyn : IScriptDynArray;
begin
   EvalAsScriptDynArray(exec, dyn);
   Result:=dyn;
end;

// GetDataPtr
//
procedure TDynamicArrayDataExpr.GetDataPtr(exec : TdwsExecution; var result : IDataContext);
var
   data : TData;
begin
   SetLength(data, 1);
   EvalAsVariant(exec, data[0]);
   result:=exec.Stack.CreateDataContext(data, 0);
end;

// ------------------
// ------------------ TNewArrayExpr ------------------
// ------------------

// Create
//
constructor TNewArrayExpr.Create(context : TdwsCompilerContext; const scriptPos: TScriptPos;
                                 elementTyp : TTypeSymbol);
begin
   inherited Create(scriptPos, TDynamicArraySymbol.Create('', elementTyp, context.TypInteger));
   FTyps.Add(FTyp);
end;

// Create
//
constructor TNewArrayExpr.Create(const scriptPos: TScriptPos; arrayTyp : TDynamicArraySymbol);
begin
   inherited Create(scriptPos, arrayTyp);
end;

// Destroy
//
destructor TNewArrayExpr.Destroy;
begin
   inherited;
   FTyps.Clean;
   FLengthExprs.Clean;
end;

// EvalAsScriptDynArray
//
procedure TNewArrayExpr.EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray);

   function CreateDimension(d : Integer) : TScriptDynamicArray;
   var
      i : Integer;
      n : Int64;
   begin
      n:=LengthExpr[d].EvalAsInteger(exec);
      if n<0 then
         RaiseScriptError(exec, EScriptOutOfBounds.CreatePosFmt(ScriptPos, RTE_ArrayLengthIncorrectForDimension, [n, d]));
      Result:=TScriptDynamicArray.CreateNew(TDynamicArraySymbol(FTyps.List[FTyps.Count-1-d]).Typ);
      Result.ArrayLength:=n;
      Inc(d);
      if d<LengthExprCount then begin
         for i:=0 to n-1 do
            Result.AsInterface[i]:=IScriptDynArray(CreateDimension(d));
      end;
   end;

begin
   if LengthExprCount>0 then
      result:=CreateDimension(0)
   else result:=TScriptDynamicArray.CreateNew(Typ.Typ);
end;

// AddLengthExpr
//
procedure TNewArrayExpr.AddLengthExpr(expr : TTypedExpr; indexTyp : TTypeSymbol);
begin
   if FLengthExprs.Count>0 then begin
      FTyp:=TDynamicArraySymbol.Create('', FTyp, indexTyp);
      FTyps.Add(FTyp);
   end;
   FLengthExprs.Add(expr);
end;

// GetLengthExpr
//
function TNewArrayExpr.GetLengthExpr(idx : Integer) : TTypedExpr;
begin
   Result:=TTypedExpr(FLengthExprs.List[idx]);
end;

// GetSubExpr
//
function TNewArrayExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   Result:=TExprBase(FLengthExprs.List[i]);
end;

// GetSubExprCount
//
function TNewArrayExpr.GetSubExprCount : Integer;
begin
   Result:=FLengthExprs.Count;
end;

// ------------------
// ------------------ TArrayExpr ------------------
// ------------------

// Create
//
constructor TArrayExpr.Create(const aScriptPos: TScriptPos;
                              BaseExpr: TDataExpr; IndexExpr: TTypedExpr;
                              arraySymbol : TArraySymbol);
begin
   inherited Create(aScriptPos, arraySymbol.Typ);
   FBaseExpr := BaseExpr;
   FIndexExpr := IndexExpr;
   FElementSize := FTyp.Size; // Necessary because of arrays of records!
end;

// Destroy
//
destructor TArrayExpr.Destroy;
begin
   FBaseExpr.Free;
   FIndexExpr.Free;
   inherited;
end;

// Orphan
//
procedure TArrayExpr.Orphan(context : TdwsCompilerContext);
begin
   if FBaseExpr <> nil then begin
      FBaseExpr.Orphan(context);
      FBaseExpr := nil;
   end;
   if FIndexExpr <> nil then begin
      FIndexExpr.Orphan(context);
      FIndexExpr := nil;
   end;
   DecRefCount;
end;

// IsWritable
//
function TArrayExpr.IsWritable : Boolean;
begin
   Result:=FBaseExpr.IsWritable;
end;

// SameDataExpr
//
function TArrayExpr.SameDataExpr(expr : TTypedExpr) : Boolean;
begin
   Result:=    (ClassType=expr.ClassType)
           and BaseExpr.SameDataExpr(TArrayExpr(expr).BaseExpr)
           and IndexExpr.SameDataExpr(TArrayExpr(expr).IndexExpr);
end;

// GetSubExpr
//
function TArrayExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   if i=0 then
      Result:=FBaseExpr
   else Result:=FIndexExpr;
end;

// GetSubExprCount
//
function TArrayExpr.GetSubExprCount : Integer;
begin
   Result:=2;
end;

// GetBaseType
//
function TArrayExpr.GetBaseType : TTypeSymbol;
begin
   Result:=FTyp;
end;

// ------------------
// ------------------ TStaticArrayExpr ------------------
// ------------------

// Create
//
constructor TStaticArrayExpr.Create(const aScriptPos: TScriptPos;
                                    baseExpr : TDataExpr; indexExpr : TTypedExpr;
                                    arraySymbol : TStaticArraySymbol);
begin
   inherited Create(aScriptPos, BaseExpr, IndexExpr, arraySymbol);
   FLowBound:=arraySymbol.LowBound;
   FCount:=arraySymbol.HighBound-arraySymbol.LowBound+1;
end;

// GetIsConstant
//
function TStaticArrayExpr.GetIsConstant : Boolean;
begin
   Result:=BaseExpr.IsConstant and IndexExpr.IsConstant;
end;

// Optimize
//
function TStaticArrayExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;

   function DoOptimize(exec : TdwsExecution) : TProgramExpr;
   var
      v : Variant;
      dc : IDataContext;
   begin
      if Typ.Size=1 then begin
         EvalAsVariant(exec, v);
         Result := TConstExpr.Create(Typ, v);
      end else begin
         dc := DataPtr[exec];
         Result := TConstExpr.Create(Typ, dc.AsPData^, dc.Addr);
      end;
      Orphan(context);
   end;

begin
   if IsConstant then
      Result := DoOptimize(context.Execution)
   else Result := Self;
end;

// AssignExpr
//
procedure TStaticArrayExpr.AssignExpr(exec : TdwsExecution; expr : TTypedExpr);
var
   arrayData : IDataContext;
begin
   FBaseExpr.GetDataPtr(exec, arrayData);
   expr.EvalAsVariant(exec, arrayData.AsPVariant(GetIndex(exec))^);
end;

// AssignValueAsInteger
//
procedure TStaticArrayExpr.AssignValueAsInteger(exec : TdwsExecution; const value : Int64);
begin
   FBaseExpr.DataPtr[exec].AsInteger[GetIndex(exec)]:=value;
end;

// AssignValueAsBoolean
//
procedure TStaticArrayExpr.AssignValueAsBoolean(exec : TdwsExecution; const value : Boolean);
begin
   FBaseExpr.DataPtr[exec].AsBoolean[GetIndex(exec)]:=value;
end;

// AssignValueAsFloat
//
procedure TStaticArrayExpr.AssignValueAsFloat(exec : TdwsExecution; const value : Double);
begin
   FBaseExpr.DataPtr[exec].AsFloat[GetIndex(exec)]:=value;
end;

// AssignValueAsString
//
procedure TStaticArrayExpr.AssignValueAsString(exec : TdwsExecution; const value: String);
begin
   FBaseExpr.DataPtr[exec].AsString[GetIndex(exec)]:=value;
end;

// EvalAsInteger
//
function TStaticArrayExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
var
   dc : IDataContext;
begin
   FBaseExpr.GetDataPtr(exec, dc);
   Result := dc.AsInteger[GetIndex(exec)];
end;

// EvalAsFloat
//
function TStaticArrayExpr.EvalAsFloat(exec : TdwsExecution) : Double;
var
   dc : IDataContext;
begin
   FBaseExpr.GetDataPtr(exec, dc);
   Result := dc.AsFloat[GetIndex(exec)];
end;

// EvalAsBoolean
//
function TStaticArrayExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
begin
   Result:=FBaseExpr.DataPtr[exec].AsBoolean[GetIndex(exec)];
end;

// EvalAsVariant
//
procedure TStaticArrayExpr.EvalAsVariant(exec : TdwsExecution; var result : Variant);
begin
   FBaseExpr.DataPtr[exec].EvalAsVariant(GetIndex(exec), result);
end;

// EvalAsString
//
procedure TStaticArrayExpr.EvalAsString(exec : TdwsExecution; var result : String);
begin
   FBaseExpr.DataPtr[exec].EvalAsString(GetIndex(exec), Result);
end;

// GetDataPtr
//
procedure TStaticArrayExpr.GetDataPtr(exec : TdwsExecution; var result : IDataContext);
begin
   FBaseExpr.GetDataPtr(exec, result);
   result.CreateOffset(GetIndex(exec), result);
end;

// GetIndex
//
function TStaticArrayExpr.GetIndex(exec : TdwsExecution) : Integer;
begin
   // Get index
   Result:=FIndexExpr.EvalAsInteger(exec)-FLowBound;

   if Cardinal(Result)>=Cardinal(FCount) then begin
      if Result>=FCount then
         RaiseUpperExceeded(exec, Result+FLowBound)
      else RaiseLowerExceeded(exec, Result+FLowBound);
   end;

   Result:=Result*FElementSize;
end;

// ------------------
// ------------------ TStaticArrayBoolExpr ------------------
// ------------------

// GetIndex
//
function TStaticArrayBoolExpr.GetIndex(exec : TdwsExecution) : Integer;
begin
   if FIndexExpr.EvalAsBoolean(exec) then
      Result:=FElementSize
   else Result:=0;
end;

// ------------------
// ------------------ TOpenArrayExpr ------------------
// ------------------

// GetDataPtr
//
procedure TOpenArrayExpr.GetDataPtr(exec : TdwsExecution; var result : IDataContext);
var
   index : Integer;
begin
   index := FIndexExpr.EvalAsInteger(exec);

   Result := FBaseExpr.DataPtr[exec];

   BoundsCheck(exec, Result.DataLength, index);

   result.CreateOffset(index, result);
end;

// IsWritable
//
function TOpenArrayExpr.IsWritable : Boolean;
begin
   Result:=False;
end;

// ------------------
// ------------------ TDynamicArrayExpr ------------------
// ------------------

// GetDataPtr
//
procedure TDynamicArrayExpr.GetDataPtr(exec : TdwsExecution; var result : IDataContext);
var
   base : IScriptDynArray;
   index : Integer;
begin
   FBaseExpr.EvalAsScriptDynArray(exec, base);

   index:=IndexExpr.EvalAsInteger(exec);
   BoundsCheck(exec, base.ArrayLength, index);

   exec.DataContext_CreateOffset(base, index*FElementSize, Result);
end;

// EvalItem
//
function TDynamicArrayExpr.EvalItem(exec : TdwsExecution; var dyn : IScriptDynArray) : PVariant;
var
   dynArray : TScriptDynamicArray;
   index : Integer;
begin
   FBaseExpr.EvalAsScriptDynArray(exec, dyn);
   dynArray:=TScriptDynamicArray(dyn.GetSelf);

   index:=IndexExpr.EvalAsInteger(exec);
   BoundsCheck(exec, dynArray.ArrayLength, index);

   Result:=dynArray.AsPVariant(index*FElementSize);
end;

// EvalAsInteger
//
function TDynamicArrayExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
var
   dyn : IScriptDynArray;
   p : PVarData;
begin
   p:=PVarData(EvalItem(exec, dyn));
   if p.VType=varInt64 then
      Result:=p.VInt64
   else VariantToInt64(PVariant(p)^, Result);
end;

// EvalAsFloat
//
function TDynamicArrayExpr.EvalAsFloat(exec : TdwsExecution) : Double;
var
   dyn : IScriptDynArray;
   p : PVarData;
begin
   p:=PVarData(EvalItem(exec, dyn));
   if p.VType=varDouble then
      Result:=p.VDouble
   else Result:=VariantToFloat(PVariant(p)^);
end;

// EvalAsVariant
//
procedure TDynamicArrayExpr.EvalAsVariant(exec : TdwsExecution; var result : Variant);
var
   dyn : IScriptDynArray;
begin
   VarCopySafe(result, EvalItem(exec, dyn)^);
end;

// EvalAsString
//
procedure TDynamicArrayExpr.EvalAsString(exec : TdwsExecution; var result : String);
var
   dyn : IScriptDynArray;
   p : PVarData;
begin
   p:=PVarData(EvalItem(exec, dyn));
   {$ifdef FPC}
   if p.VType=varString then
      Result:=String(p.VString)
   {$else}
   if p.VType=varUString then
      Result:=String(p.VUString)
   {$endif}
   else VariantToString(PVariant(p)^, Result);
end;

// SpecializeDataExpr
//
function TDynamicArrayExpr.SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr;
begin
   Result := TDynamicArrayExpr.Create(
      ScriptPos,
      BaseExpr.SpecializeDataExpr(context), IndexExpr.SpecializeTypedExpr(context),
      context.SpecializeType(BaseExpr.Typ) as TArraySymbol
      );
end;

// CreateArrayElementDataContext
//
procedure TDynamicArrayExpr.CreateArrayElementDataContext(
      exec : TdwsExecution; var result : IDataContext);
var
   dyn : IScriptDynArray;
   index : Integer;
begin
   FBaseExpr.EvalAsScriptDynArray(exec, dyn);

   index := IndexExpr.EvalAsInteger(exec);
   BoundsCheck(exec, dyn.ArrayLength, index);

   result := TArrayElementDataContext.Create(dyn, index);
end;

// ------------------
// ------------------ TDynamicArrayVarExpr ------------------
// ------------------

// EvalItem
//
function TDynamicArrayVarExpr.EvalItem(exec : TdwsExecution) : PVariant;
var
   pIDyn : PIUnknown;
   dynArray : TScriptDynamicArray;
   index : Integer;
begin
   pIDyn := exec.Stack.PointerToInterfaceValue_BaseRelative(TObjectVarExpr(FBaseExpr).FStackAddr);
   dynArray := TScriptDynamicArray(IScriptDynArray(pIDyn^).GetSelf);

   index:=IndexExpr.EvalAsInteger(exec);
   BoundsCheck(exec, dynArray.ArrayLength, index);

   Result:=dynArray.AsPVariant(index*FElementSize);
end;

// EvalAsInteger
//
function TDynamicArrayVarExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
var
   p : PVarData;
begin
   p:=PVarData(EvalItem(exec));
   if p.VType=varInt64 then
      Result:=p.VInt64
   else VariantToInt64(PVariant(p)^, Result);
end;

// EvalAsFloat
//
function TDynamicArrayVarExpr.EvalAsFloat(exec : TdwsExecution) : Double;
var
   p : PVarData;
begin
   p:=PVarData(EvalItem(exec));
   if p.VType=varDouble then
      Result:=p.VDouble
   else Result:=VariantToFloat(PVariant(p)^);
end;

// EvalAsString
//
procedure TDynamicArrayVarExpr.EvalAsString(exec : TdwsExecution; var result : String);
var
   p : PVarData;
begin
   p:=PVarData(EvalItem(exec));
   {$ifdef FPC}
   if p.VType=varString then
      Result:=String(p.VString)
   {$else}
   if p.VType=varUString then
      Result:=String(p.VUString)
   {$endif}
   else VariantToString(PVariant(p)^, Result);
end;

// SpecializeDataExpr
//
function TDynamicArrayVarExpr.SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr;
begin
   Result := TDynamicArrayVarExpr.Create(
      ScriptPos,
      BaseExpr.SpecializeDataExpr(context), IndexExpr.SpecializeTypedExpr(context),
      context.SpecializeType(BaseExpr.Typ) as TArraySymbol
      );
end;

// ------------------
// ------------------ TDynamicArraySetExpr ------------------
// ------------------

// Create
//
constructor TDynamicArraySetExpr.Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                            arrayExpr, indexExpr, valueExpr : TTypedExpr);
begin
   inherited Create(scriptPos);
   FArrayExpr:=arrayExpr;
   FIndexExpr:=indexExpr;
   FValueExpr:=valueExpr;
end;

// Destroy
//
destructor TDynamicArraySetExpr.Destroy;
begin
   inherited;
   FArrayExpr.Free;
   FIndexExpr.Free;
   FValueExpr.Free;
end;

// EvalNoResult
//
procedure TDynamicArraySetExpr.EvalNoResult(exec : TdwsExecution);
var
   dynArray : TScriptDynamicArray;
   index : Integer;
   base : IScriptDynArray;
begin
   FArrayExpr.EvalAsScriptDynArray(exec, base);
   dynArray:=TScriptDynamicArray(base.GetSelf);
   index:=IndexExpr.EvalAsInteger(exec);
   BoundsCheck(exec, dynArray.ArrayLength, index);
   ValueExpr.EvalAsVariant(exec, dynArray.AsPVariant(index)^);
end;

// GetSubExpr
//
function TDynamicArraySetExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   case i of
      0 : Result:=FArrayExpr;
      1 : Result:=FIndexExpr
   else
      Result:=FValueExpr;
   end;
end;

// GetSubExprCount
//
function TDynamicArraySetExpr.GetSubExprCount : Integer;
begin
   Result:=3;
end;

// ------------------
// ------------------ TDynamicArraySetVarExpr ------------------
// ------------------

// EvalNoResult
//
procedure TDynamicArraySetVarExpr.EvalNoResult(exec : TdwsExecution);
var
   dyn : IScriptDynArray;
   index : Integer;
begin
   ArrayExpr.EvalAsScriptDynArray(exec, dyn);
   index:=IndexExpr.EvalAsInteger(exec);
   BoundsCheck(exec, dyn.ArrayLength, index);
   ValueExpr.EvalAsVariant(exec, dyn.AsPVariant(index)^);
end;

// ------------------
// ------------------ TDynamicArraySetDataExpr ------------------
// ------------------

// EvalNoResult
//
procedure TDynamicArraySetDataExpr.EvalNoResult(exec : TdwsExecution);
var
   dynArray : TScriptDynamicArray;
   index : Integer;
   base : IScriptDynArray;
   dataExpr : TDataExpr;
begin
   FArrayExpr.EvalAsScriptDynArray(exec, base);
   dynArray:=TScriptDynamicArray(base.GetSelf);
   index:=IndexExpr.EvalAsInteger(exec);
   BoundsCheck(exec, dynArray.ArrayLength, index);

   dataExpr := (ValueExpr as TDataExpr);
   dynArray.WriteData(index*dynArray.ElementSize, dataExpr.DataPtr[exec], dynArray.ElementSize);
end;

// ------------------
// ------------------ TAssociativeArrayGetExpr ------------------
// ------------------

// Create
//
constructor TAssociativeArrayGetExpr.Create(const aScriptPos: TScriptPos;
                            baseExpr: TDataExpr; keyExpr: TTypedExpr;
                            arraySymbol : TAssociativeArraySymbol);
begin
   inherited Create(aScriptPos, arraySymbol.Typ);
   FBaseExpr := baseExpr;
   FKeyExpr := KeyExpr;
   FElementSize := FTyp.Size; // Necessary because of arrays of records!
end;

// Destroy
//
destructor TAssociativeArrayGetExpr.Destroy;
begin
   inherited;
   FBaseExpr.Free;
   FKeyExpr.Free;
end;

// GetSubExpr
//
function TAssociativeArrayGetExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   if i=0 then
      Result:=FBaseExpr
   else Result:=FKeyExpr;
end;

// GetSubExprCount
//
function TAssociativeArrayGetExpr.GetSubExprCount : Integer;
begin
   Result:=2;
end;

// GetBaseType
//
function TAssociativeArrayGetExpr.GetBaseType : TTypeSymbol;
begin
   Result:=FTyp;
end;

// IsWritable
//
function TAssociativeArrayGetExpr.IsWritable : Boolean;
begin
   Result:=FBaseExpr.IsWritable;
end;

// SameDataExpr
//
function TAssociativeArrayGetExpr.SameDataExpr(expr : TTypedExpr) : Boolean;
begin
   Result:=    (ClassType=expr.ClassType)
           and BaseExpr.SameDataExpr(TAssociativeArrayGetExpr(expr).BaseExpr)
           and KeyExpr.SameDataExpr(TAssociativeArrayGetExpr(expr).KeyExpr);
end;

// GetDataPtr
//
procedure TAssociativeArrayGetExpr.GetDataPtr(exec : TdwsExecution; var result : IDataContext);
var
   base : IScriptAssociativeArray;
begin
   FBaseExpr.EvalAsScriptAssociativeArray(exec, base);

   TScriptAssociativeArray(base.GetSelf).GetDataPtr(exec, KeyExpr, result);
end;

// EvalAsInteger
//
function TAssociativeArrayGetExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
var
   base : IScriptAssociativeArray;
begin
   FBaseExpr.EvalAsScriptAssociativeArray(exec, base);
   Result := TScriptAssociativeArray(base.GetSelf).GetDataAsInteger(exec, KeyExpr);
end;

// EvalAsBoolean
//
function TAssociativeArrayGetExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   base : IScriptAssociativeArray;
begin
   FBaseExpr.EvalAsScriptAssociativeArray(exec, base);
   Result := TScriptAssociativeArray(base.GetSelf).GetDataAsBoolean(exec, KeyExpr);
end;

// ------------------
// ------------------ TAssociativeArrayValueKeyGetExpr ------------------
// ------------------

// EvalAsInteger
//
function TAssociativeArrayValueKeyGetExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
var
   base : IScriptAssociativeArray;
   key : Variant;
begin
   FBaseExpr.EvalAsScriptAssociativeArray(exec, base);
   KeyExpr.EvalAsVariant(exec, key);
   Result := TScriptAssociativeArray(base.GetSelf).GetDataAsInteger(exec, key);
end;

// ------------------
// ------------------ TAssociativeArraySetExpr ------------------
// ------------------

// Create
//
constructor TAssociativeArraySetExpr.Create(const aScriptPos: TScriptPos;
                                            baseExpr: TDataExpr; keyExpr, valueExpr: TTypedExpr);
begin
   inherited Create(aScriptPos);
   FBaseExpr:=baseExpr;
   FKeyExpr:=keyExpr;
   FValueExpr:=valueExpr;
end;

// Destroy
//
destructor TAssociativeArraySetExpr.Destroy;
begin
   inherited;
   FBaseExpr.Free;
   FKeyExpr.Free;
   FValueExpr.Free;
end;

// GetSubExpr
//
function TAssociativeArraySetExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   case i of
      0 : Result:=FBaseExpr;
      1 : Result:=FKeyExpr;
   else
      Result:=FValueExpr;
   end;
end;

// GetSubExprCount
//
function TAssociativeArraySetExpr.GetSubExprCount : Integer;
begin
   Result:=3;
end;

// EvalNoResult
//
procedure TAssociativeArraySetExpr.EvalNoResult(exec : TdwsExecution);
var
   aa : TScriptAssociativeArray;
   base : IScriptAssociativeArray;
begin
   FBaseExpr.EvalAsScriptAssociativeArray(exec, base);
   aa:=TScriptAssociativeArray(base.GetSelf);
   aa.ReplaceValue(exec, KeyExpr, valueExpr);
end;

// ------------------
// ------------------ TAssociativeArrayContainsKeyExpr ------------------
// ------------------

// EvalAsBoolean
//
function TAssociativeArrayContainsKeyExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   base : IScriptAssociativeArray;
begin
   FRight.EvalAsScriptAssociativeArray(exec, base);
   Result := TScriptAssociativeArray(base.GetSelf).ContainsKey(exec, Left);
end;

// ------------------
// ------------------ TRecordExpr ------------------
// ------------------

// Create
//
constructor TRecordExpr.Create(const aScriptPos: TScriptPos;
                               BaseExpr: TDataExpr; fieldSymbol: TFieldSymbol);
begin
   inherited Create(aScriptPos, fieldSymbol.Typ);
   FBaseExpr := BaseExpr;
   FMemberOffset := fieldSymbol.Offset;
   FFieldSymbol := fieldSymbol;
end;

// Destroy
//
destructor TRecordExpr.Destroy;
begin
   FBaseExpr.Free;
   inherited;
end;

// Orphan
//
procedure TRecordExpr.Orphan(context : TdwsCompilerContext);
begin
   if FBaseExpr <> nil then begin
      FBaseExpr.Orphan(context);
      FBaseExpr := nil;
      DecRefCount;
   end else inherited;
end;

// GetIsConstant
//
function TRecordExpr.GetIsConstant : Boolean;
begin
   Result:=BaseExpr.IsConstant;
end;

// EvalAsBoolean
//
function TRecordExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
begin
   Result:=FBaseExpr.DataPtr[exec].AsBoolean[FMemberOffset];
end;

// EvalAsInteger
//
function TRecordExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=FBaseExpr.DataPtr[exec].AsInteger[FMemberOffset];
end;

// EvalAsFloat
//
function TRecordExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   Result:=FBaseExpr.DataPtr[exec].AsFloat[FMemberOffset];
end;

// EvalAsVariant
//
procedure TRecordExpr.EvalAsVariant(exec : TdwsExecution; var result : Variant);
begin
   FBaseExpr.DataPtr[exec].EvalAsVariant(FMemberOffset, result);
end;

// EvalAsString
//
procedure TRecordExpr.EvalAsString(exec : TdwsExecution; var result : String);
begin
   FBaseExpr.DataPtr[exec].EvalAsString(FMemberOffset, Result);
end;

// GetDataPtr
//
procedure TRecordExpr.GetDataPtr(exec : TdwsExecution; var result : IDataContext);
begin
   FBaseExpr.GetDataPtr(exec, result);
   result.CreateOffset(FMemberOffset, result);
end;

// SameDataExpr
//
function TRecordExpr.SameDataExpr(expr : TTypedExpr) : Boolean;
begin
   Result:=    (ClassType=expr.ClassType)
           and (FieldSymbol=TRecordExpr(expr).FieldSymbol)
           and BaseExpr.SameDataExpr(TRecordExpr(expr).BaseExpr);
end;

// SpecializeDataExpr
//
function TRecordExpr.SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr;
begin
   Result := TRecordExpr.Create(ScriptPos, BaseExpr.SpecializeDataExpr(context),
                                context.SpecializeField(FieldSymbol));
end;

// AssignExpr
//
procedure TRecordExpr.AssignExpr(exec : TdwsExecution; Expr: TTypedExpr);
var
   context : IDataContext;
begin
   FBaseExpr.GetDataPtr(exec, context);
   Expr.EvalAsVariant(exec, context.AsPVariant(FMemberOffset)^);
end;

// AssignValueAsInteger
//
procedure TRecordExpr.AssignValueAsInteger(exec : TdwsExecution; const value : Int64);
var
   context : IDataContext;
begin
   FBaseExpr.GetDataPtr(exec, context);
   context.AsInteger[FMemberOffset]:=value;
end;

// AssignValueAsBoolean
//
procedure TRecordExpr.AssignValueAsBoolean(exec : TdwsExecution; const value : Boolean);
var
   context : IDataContext;
begin
   FBaseExpr.GetDataPtr(exec, context);
   context.AsBoolean[FMemberOffset]:=value;
end;

// AssignValueAsFloat
//
procedure TRecordExpr.AssignValueAsFloat(exec : TdwsExecution; const value : Double);
var
   context : IDataContext;
begin
   FBaseExpr.GetDataPtr(exec, context);
   context.AsFloat[FMemberOffset]:=value;
end;

// AssignValueAsString
//
procedure TRecordExpr.AssignValueAsString(exec : TdwsExecution; const value: String);
var
   context : IDataContext;
begin
   FBaseExpr.GetDataPtr(exec, context);
   context.AsString[FMemberOffset]:=value;
end;

// AssignValueAsScriptObj
//
procedure TRecordExpr.AssignValueAsScriptObj(exec : TdwsExecution; const value : IScriptObj);
var
   context : IDataContext;
begin
   FBaseExpr.GetDataPtr(exec, context);
   context.AsInterface[FMemberOffset]:=value;
end;

// GetSubExpr
//
function TRecordExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   Result:=FBaseExpr;
end;

// GetSubExprCount
//
function TRecordExpr.GetSubExprCount : Integer;
begin
   Result:=1;
end;

// IsWritable
//
function TRecordExpr.IsWritable : Boolean;
begin
   Result:=FBaseExpr.IsWritable and not FieldSymbol.StructSymbol.IsImmutable;
end;

// ------------------
// ------------------ TRecordVarExpr ------------------
// ------------------

// Create
//
constructor TRecordVarExpr.Create(const aScriptPos: TScriptPos; baseExpr: TVarExpr;
                                  fieldSymbol : TFieldSymbol);
begin
   inherited Create(aScriptPos, baseExpr, fieldSymbol);
   FVarPlusMemberOffset:=MemberOffset+baseExpr.StackAddr;
end;

// EvalAsInteger
//
function TRecordVarExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=exec.Stack.ReadIntValue_BaseRelative(VarPlusMemberOffset);
end;

// EvalAsFloat
//
function TRecordVarExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   Result:=exec.Stack.ReadFloatValue_BaseRelative(VarPlusMemberOffset);
end;

// EvalAsVariant
//
procedure TRecordVarExpr.EvalAsVariant(exec : TdwsExecution; var result : Variant);
begin
   exec.Stack.ReadValue(exec.Stack.BasePointer+VarPlusMemberOffset, result);
end;

// EvalAsString
//
procedure TRecordVarExpr.EvalAsString(exec : TdwsExecution; var result : String);
begin
   exec.Stack.ReadStrValue(exec.Stack.BasePointer+VarPlusMemberOffset, result);
end;

// GetDataPtr
//
procedure TRecordVarExpr.GetDataPtr(exec : TdwsExecution; var result : IDataContext);
begin
   exec.DataContext_CreateBase(VarPlusMemberOffset, Result);
end;

// ------------------
// ------------------ TInitDataExpr ------------------
// ------------------

// Create
//
constructor TInitDataExpr.Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos; Expr: TDataExpr);
begin
   inherited Create(aScriptPos);
   FExpr := Expr;
end;

// Destroy
//
destructor TInitDataExpr.Destroy;
begin
   FExpr.Free;
   inherited;
end;

// SpecializeProgramExpr
//
function TInitDataExpr.SpecializeProgramExpr(const context : ISpecializationContext) : TProgramExpr;
begin
   Result := TInitDataExpr.Create(
      CompilerContextFromSpecialization(context),
      ScriptPos,
      Expr.SpecializeDataExpr(context)
   );
end;

// EvalNoResult
//
procedure TInitDataExpr.EvalNoResult(exec : TdwsExecution);
var
   dc : IDataContext;
begin
   FExpr.GetDataPtr(exec, dc);
   FExpr.Typ.InitDataContext(dc);
end;

// GetSubExpr
//
function TInitDataExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   Result:=FExpr;
end;

// GetSubExprCount
//
function TInitDataExpr.GetSubExprCount : Integer;
begin
   Result:=1;
end;

// ------------------
// ------------------ TDynamicRecordExpr ------------------
// ------------------

// Create
//
constructor TDynamicRecordExpr.Create(context : TdwsCompilerContext; const aPos : TScriptPos;
                                      recordTyp : TRecordSymbol);
begin
   inherited Create(aPos, recordTyp);
   FAddr:=context.GetTempAddr(recordTyp.Size);
end;

// EvalNoResult
//
procedure TDynamicRecordExpr.EvalNoResult(exec : TdwsExecution);
var
   recType : TRecordSymbol;
   sym : TSymbol;
   expr : TExprBase;
   dataExpr : TDataExpr;
   fieldSym : TFieldSymbol;
   fieldAddr : Integer;
begin
   recType:=TRecordSymbol(Typ);
   for sym in recType.Members do begin
      if sym.ClassType=TFieldSymbol then begin
         fieldSym := TFieldSymbol(sym);
         expr := fieldSym.DefaultExpr;
         if expr = nil then
            fieldSym.InitData(exec.Stack.Data, exec.Stack.BasePointer+FAddr)
         else begin
            fieldAddr := exec.Stack.BasePointer+FAddr+fieldSym.Offset;
            if (expr is TDataExpr) and (TDataExpr(expr).Typ.Size > 1) then begin
               dataExpr := TDataExpr(expr);
               dataExpr.DataPtr[exec].CopyData(exec.Stack.Data, fieldAddr, fieldSym.Size);
            end else expr.EvalAsVariant(exec, exec.Stack.Data[fieldAddr]);
         end;
      end;
   end;
end;

// GetDataPtr
//
procedure TDynamicRecordExpr.GetDataPtr(exec : TdwsExecution; var result : IDataContext);
begin
   EvalNoResult(exec);
   exec.DataContext_CreateBase(FAddr, Result);
end;

// GetSubExpr
//
function TDynamicRecordExpr.GetSubExpr(i : Integer) : TExprBase;
var
   recType : TRecordSymbol;
   sym : TSymbol;
   k : Integer;
begin
   recType:=TRecordSymbol(Typ);
   for k:=0 to recType.Members.Count-1 do begin
      sym:=recType.Members[k];
      if sym.ClassType=TFieldSymbol then begin
         Result:=TFieldSymbol(sym).DefaultExpr;
         if i=0 then
            Exit
         else Dec(i);
      end;
   end;
   Result:=nil;
end;

// GetSubExprCount
//
function TDynamicRecordExpr.GetSubExprCount : Integer;
var
   recType : TRecordSymbol;
   sym : TSymbol;
   k : Integer;
begin
   Result:=0;
   recType:=TRecordSymbol(Typ);
   for k:=0 to recType.Members.Count-1 do begin
      sym:=recType.Members[k];
      if sym.ClassType=TFieldSymbol then begin
         if TFieldSymbol(sym).DefaultExpr<>nil then
            Inc(Result);
      end;
   end;
end;

// ------------------
// ------------------ TFieldExpr ------------------
// ------------------

// Create
//
constructor TFieldExpr.Create(const aScriptPos: TScriptPos;
                              fieldSym: TFieldSymbol; objExpr: TTypedExpr);
begin
   inherited Create(aScriptPos, fieldSym.Typ);
   FObjectExpr := objExpr;
   FFieldSym := fieldSym;
end;

// Destroy
//
destructor TFieldExpr.Destroy;
begin
   FObjectExpr.Free;
   inherited;
end;

// AssignValueAsInteger
//
procedure TFieldExpr.AssignValueAsInteger(exec : TdwsExecution; const value : Int64);
begin
   GetScriptObj(exec).AsInteger[FieldSym.Offset]:=value;
end;

// AssignValueAsBoolean
//
procedure TFieldExpr.AssignValueAsBoolean(exec : TdwsExecution; const value : Boolean);
begin
   GetScriptObj(exec).AsBoolean[FieldSym.Offset]:=value;
end;

// AssignValueAsFloat
//
procedure TFieldExpr.AssignValueAsFloat(exec : TdwsExecution; const value : Double);
begin
   GetScriptObj(exec).AsFloat[FieldSym.Offset]:=value;
end;

// AssignValueAsString
//
procedure TFieldExpr.AssignValueAsString(exec : TdwsExecution; const value: String);
begin
   GetScriptObj(exec).AsString[FieldSym.Offset]:=value;
end;

// AssignValueAsScriptObj
//
procedure TFieldExpr.AssignValueAsScriptObj(exec : TdwsExecution; const value : IScriptObj);
begin
   GetScriptObj(exec).AsInterface[FieldSym.Offset]:=value;
end;

// GetSubExpr
//
function TFieldExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   Result:=FObjectExpr;
end;

// GetSubExprCount
//
function TFieldExpr.GetSubExprCount : Integer;
begin
   Result:=1;
end;

// GetScriptObj
//
function TFieldExpr.GetScriptObj(exec : TdwsExecution) : IScriptObj;
begin
   FObjectExpr.EvalAsScriptObj(exec, Result);
   CheckScriptObject(exec, Result);
end;

// GetDataPtr
//
procedure TFieldExpr.GetDataPtr(exec : TdwsExecution; var result : IDataContext);
begin
   exec.DataContext_CreateOffset(GetScriptObj(exec), FieldSym.Offset, result);
end;

// SameDataExpr
//
function TFieldExpr.SameDataExpr(expr : TTypedExpr) : Boolean;
begin
   Result:=    (ClassType=expr.ClassType)
           and (FieldSym=TFieldExpr(expr).FieldSym)
           and ObjectExpr.SameDataExpr(TFieldExpr(expr).ObjectExpr);
end;

// EvalAsString
//
procedure TFieldExpr.EvalAsString(exec : TdwsExecution; var result : String);
begin
   GetScriptObj(exec).EvalAsString(FieldSym.Offset, Result);
end;

// EvalAsVariant
//
procedure TFieldExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
begin
   GetScriptObj(exec).EvalAsVariant(FieldSym.Offset, Result);
end;

// EvalAsInteger
//
function TFieldExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=GetScriptObj(exec).AsInteger[FieldSym.Offset];
end;

// EvalAsFloat
//
function TFieldExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   Result:=GetScriptObj(exec).AsFloat[FieldSym.Offset];
end;

// EvalAsBoolean
//
function TFieldExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
begin
   Result:=GetScriptObj(exec).AsBoolean[FieldSym.Offset];
end;

// EvalAsScriptObj
//
procedure TFieldExpr.EvalAsScriptObj(exec : TdwsExecution; var Result : IScriptObj);
begin
   GetScriptObj(exec).EvalAsInterface(FieldSym.Offset, PIUnknown(@Result)^);
end;

// ------------------
// ------------------ TFieldVarExpr ------------------
// ------------------

// GetPIScriptObj
//
function TFieldVarExpr.GetPIScriptObj(exec : TdwsExecution) : PIScriptObj;
begin
   Result:=PIScriptObj(exec.Stack.PointerToInterfaceValue_BaseRelative(TObjectVarExpr(FObjectExpr).StackAddr));
   CheckScriptObject(exec, Result^);
end;

// AssignValueAsInteger
//
procedure TFieldVarExpr.AssignValueAsInteger(exec : TdwsExecution; const value : Int64);
begin
   GetPIScriptObj(exec)^.AsInteger[FieldSym.Offset]:=value;
end;

// EvalAsInteger
//
function TFieldVarExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=GetPIScriptObj(exec)^.AsInteger[FieldSym.Offset];
end;

// EvalAsFloat
//
function TFieldVarExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   Result:=GetPIScriptObj(exec)^.AsFloat[FieldSym.Offset];
end;

// EvalAsBoolean
//
function TFieldVarExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
begin
   Result:=GetPIScriptObj(exec)^.AsBoolean[FieldSym.Offset];
end;

// GetDataPtr
//
procedure TFieldVarExpr.GetDataPtr(exec : TdwsExecution; var result : IDataContext);
var
   p : PIScriptObj;
begin
   p:=PIScriptObj(exec.Stack.PointerToInterfaceValue_BaseRelative(TObjectVarExpr(FObjectExpr).StackAddr));
   CheckScriptObject(exec, p^);
   exec.DataContext_CreateOffset(p^, FieldSym.Offset, result);
end;

// SpecializeDataExpr
//
function TFieldVarExpr.SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr;
begin
   Result := TFieldVarExpr.Create(ScriptPos, context.SpecializeField(FieldSym),
                                  ObjectExpr.SpecializeTypedExpr(context));
end;

// ------------------
// ------------------ TReadOnlyFieldExpr ------------------
// ------------------

// Create
//
constructor TReadOnlyFieldExpr.Create(const aScriptPos: TScriptPos;
                         fieldSym : TFieldSymbol; objExpr: TTypedExpr;
                         propertyType : TTypeSymbol);
begin
   inherited Create(aScriptPos, fieldSym, objExpr);
   Typ := propertyType;
end;

// IsWritable
//
function TReadOnlyFieldExpr.IsWritable: Boolean;
begin
   Result := False;
end;

// SpecializeDataExpr
//
function TReadOnlyFieldExpr.SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr;
begin
   Result := TReadOnlyFieldExpr.Create(ScriptPos, context.SpecializeField(FieldSym),
                                       ObjectExpr.SpecializeTypedExpr(context),
                                       context.SpecializeType(Typ));
end;

// ------------------
// ------------------ TLazyParamExpr ------------------
// ------------------

// Create
//
constructor TLazyParamExpr.Create(context : TdwsCompilerContext; dataSym : TLazyParamSymbol);
begin
   FDataSym:=dataSym;
   FTyp:=dataSym.Typ;
   FLevel:=dataSym.Level;
   FStackAddr:=dataSym.StackAddr;
end;

// EvalAsVariant
//
procedure TLazyParamExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   lazyExpr : TExprBase;
   oldBasePointer, lazyBasePointer : Integer;
   {$ifdef WIN32}
   lazyContext : Int64;
   {$else}
   lazyContext : PVarData;
   {$endif}
begin
   {$ifdef WIN32}
   lazyContext:=exec.Stack.ReadIntValue(exec.Stack.BasePointer + FStackAddr);
   lazyExpr:=TExprBase(lazyContext and $FFFFFFFF);
   lazyBasePointer := lazyContext shr 32;
   {$else}
   lazyContext := @exec.Stack.Data[exec.Stack.BasePointer + FStackAddr];
   Assert(lazyContext.VType = varRecord);
   {$ifdef FPC}
     // TODO
   {$ELSE}
   lazyExpr := TExprBase(lazyContext.VRecord.PRecord);
   lazyBasePointer := Integer(lazyContext.VRecord.RecInfo);
   {$ENDIF}

   {$endif}

   oldBasePointer := exec.Stack.BasePointer;
   exec.Stack.SetBasePointer(lazyBasePointer);//  stack.GetSavedBp(Level);
   try
      lazyExpr.EvalAsVariant(exec, Result);
   finally
      exec.Stack.SetBasePointer(oldBasePointer);
   end;
end;

// SameDataExpr
//
function TLazyParamExpr.SameDataExpr(expr : TTypedExpr) : Boolean;
begin
   Result:=False;
end;

// ------------------
// ------------------ TArrayLengthExpr ------------------
// ------------------

// Create
//
constructor TArrayLengthExpr.Create(context : TdwsCompilerContext; const aScriptPos : TScriptPos; expr : TTypedExpr; captureExpr : Boolean);
begin
   inherited Create(context, aScriptPos, expr);
   FCapture:=captureExpr;
end;

// Destroy
//
destructor TArrayLengthExpr.Destroy;
begin
   if not FCapture then
      Expr:=nil;
   inherited;
end;

// SpecializeTypedExpr
//
function TArrayLengthExpr.SpecializeTypedExpr(const context : ISpecializationContext) : TTypedExpr;
begin
   Result := TArrayLengthExprClass(ClassType).Create(
      CompilerContextFromSpecialization(context), FScriptPos,
      Expr.SpecializeTypedExpr(context), True
   );
   TArrayLengthExpr(Result).Delta := Delta;
end;

// EvalAsInteger
//
function TArrayLengthExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
var
   dyn : IScriptDynArray;
begin
   FExpr.EvalAsScriptDynArray(exec, dyn);
   Result:=dyn.ArrayLength+FDelta
end;

// ------------------
// ------------------ TOpenArrayLengthExpr ------------------
// ------------------

// EvalAsInteger
//
function TOpenArrayLengthExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=TDataExpr(FExpr).DataPtr[exec].DataLength+FDelta;
end;

// ------------------
// ------------------ TAssociativeArrayLengthExpr ------------------
// ------------------

// EvalAsInteger
//
function TAssociativeArrayLengthExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
var
   aa : IScriptAssociativeArray;
begin
   Expr.EvalAsScriptAssociativeArray(exec, aa);
   Result:=aa.Count;
end;

// ------------------
// ------------------ TStringArrayOpExpr ------------------
// ------------------

// CreatePos
//
constructor TStringArrayOpExpr.CreatePos(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                                         Left, Right: TTypedExpr);
begin
   inherited Create(context, aScriptPos, ttALEFT, Left, Right);
   FScriptPos := aScriptPos;
end;

// EvalAsString
//
procedure TStringArrayOpExpr.EvalAsString(exec : TdwsExecution; var result : String);
var
   i : Integer;
   buf : String;
begin
   FLeft.EvalAsString(exec, buf);
   i:=FRight.EvalAsInteger(exec);
   if i>Length(buf) then
      RaiseUpperExceeded(exec, i)
   else if i<1 then
      RaiseLowerExceeded(exec, i);
   Result:=buf[i];
end;

// EvalAsInteger
//
function TStringArrayOpExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
var
   i : Integer;
   buf : String;
begin
   FLeft.EvalAsString(exec, buf);
   i:=FRight.EvalAsInteger(exec);
   if i>Length(buf) then
      RaiseUpperExceeded(exec, i)
   else if i<1 then
      RaiseLowerExceeded(exec, i);
   Result:=Ord(buf[i]);
end;

// ScriptPos
//
function TStringArrayOpExpr.ScriptPos : TScriptPos;
begin
   Result:=FScriptPos;
end;

// ------------------
// ------------------ TStringLengthExpr ------------------
// ------------------

// EvalAsInteger
//
function TStringLengthExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
var
   buf : String;
begin
   FExpr.EvalAsString(exec, buf);
   Result:=Length(buf);
end;

// ------------------
// ------------------ TIsOpExpr ------------------
// ------------------

// EvalAsBoolean
//
function TIsOpExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   scriptObj : IScriptObj;
begin
   FLeft.EvalAsScriptObj(exec, scriptObj);
   Result:=Assigned(scriptObj) and FRight.Typ.Typ.IsCompatible(scriptObj.ClassSym);
end;

// ------------------
// ------------------ TInOpExpr ------------------
// ------------------

// Create
//
constructor TInOpExpr.Create(context : TdwsCompilerContext; Left: TTypedExpr);
begin
   FLeft:=Left;
   FTyp:=context.TypBoolean;
end;

// Destroy
//
destructor TInOpExpr.Destroy;
begin
   FLeft.Free;
   FCaseConditions.Clean;
   inherited;
end;

// EvalAsVariant
//
procedure TInOpExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
begin
   VarCopySafe(Result, EvalAsBoolean(exec));
end;

// EvalAsBoolean
//
function TInOpExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   i : Integer;
   value : Variant;
   cc : TCaseCondition;
begin
   FLeft.EvalAsVariant(exec, value);
   for i:=0 to FCaseConditions.Count-1 do begin
      cc:=TCaseCondition(FCaseConditions.List[i]);
      if cc.IsTrue(exec, Value) then
         Exit(True);
   end;
   Result:=False;
end;

// ConstantConditions
//
function TInOpExpr.ConstantConditions : Boolean;
var
   i : Integer;
begin
   for i:=0 to FCaseConditions.Count-1 do
      if not TCaseCondition(FCaseConditions.List[i]).IsConstant then
         Exit(False);
   Result:=True;
end;

// GetIsConstant
//
function TInOpExpr.GetIsConstant : Boolean;
begin
   Result:=FLeft.IsConstant and ConstantConditions;
end;

// Optimize
//
function TInOpExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;

   procedure TransferFieldsAndOrphan(dest : TInOpExpr);
   begin
      FLeft:=nil;
      dest.FCaseConditions.Assign(FCaseConditions);
      FCaseConditions.Clear;
      Orphan(context);
   end;

var
   enumSym : TEnumerationSymbol;
   value : Variant;
   i, k, mask : Integer;
   cc : TCaseCondition;
   iioe : TIntegerInOpExpr;
begin
   Result:=Self;
   // if left is an enumeration with 31 or less symbols (31 is limit for JS)
   // and conditions are constants, then it can be optimized to a bitwise test
   if (FLeft.Typ is TEnumerationSymbol) and ConstantConditions then begin

      enumSym:=TEnumerationSymbol(FLeft.Typ);
      if (enumSym.LowBound<0) or (enumSym.HighBound>31) then Exit;
      mask:=0;
      for k:=enumSym.LowBound to enumSym.HighBound do begin
         value:=Int64(k);
         for i:=0 to FCaseConditions.Count-1 do begin
            cc:=TCaseCondition(FCaseConditions.List[i]);
            if cc.IsTrue(context.Execution, Value) then begin
               mask:=mask or (1 shl k);
               Break;
            end;
         end;
      end;
      Result:=TBitwiseInOpExpr.Create(context, ScriptPos, FLeft);
      TBitwiseInOpExpr(Result).Mask:=mask;
      FLeft:=nil;
      Orphan(context);

   end else if FLeft.IsOfType(context.TypInteger) then begin

      if TCaseConditionsHelper.CanOptimizeToTyped(FCaseConditions, TConstIntExpr) then begin
         iioe := TIntegerInOpExpr.Create(context, Left);
         TransferFieldsAndOrphan(iioe);
         Exit(iioe);
      end;

   end;
end;

// GetSubExpr
// AddCaseCondition
//
procedure TInOpExpr.AddCaseCondition(cond : TCaseCondition);
begin
   FCaseConditions.Add(cond);
end;

// Prepare
//
procedure TInOpExpr.Prepare;
begin
   // nothing here
end;

//
function TInOpExpr.GetSubExpr(i : Integer) : TExprBase;
var
   j : Integer;
   cond : TCaseCondition;
begin
   if i=0 then
      Result:=FLeft
   else begin
      Dec(i);
      for j:=0 to Count-1 do begin
         cond:=CaseConditions[j];
         if i<cond.GetSubExprCount then
            Exit(cond.GetSubExpr(i));
         Dec(i, cond.GetSubExprCount);
      end;
      Result:=nil;
   end;
end;

// GetSubExprCount
//
function TInOpExpr.GetSubExprCount : Integer;
var
   i : Integer;
begin
   Result:=1;
   for i:=0 to Count-1 do
      Inc(Result, CaseConditions[i].GetSubExprCount);
end;

// GetCaseConditions
//
function TInOpExpr.GetCaseConditions(idx : Integer) : TCaseCondition;
begin
   Result:=TCaseCondition(FCaseConditions.List[idx]);
end;

// ------------------
// ------------------ TStringInOpExpr ------------------
// ------------------

// EvalAsBoolean
//
function TStringInOpExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   i : Integer;
   value : String;
   cc : TCaseCondition;
begin
   FLeft.EvalAsString(exec, value);
   for i:=0 to FCaseConditions.Count-1 do begin
      cc:=TCaseCondition(FCaseConditions.List[i]);
      if cc.StringIsTrue(exec, value) then
         Exit(True);
   end;
   Result:=False;
end;

// ------------------
// ------------------ TCharacterInOpExpr ------------------
// ------------------

// AttemptCreate
//
class function TCharacterInOpExpr.AttemptCreate(
   context : TdwsCompilerContext; Left : TTypedExpr;
   const conditionsList : TTightList
   ) : TCharacterInOpExpr;
const
   cMaxChar = 127;
var
   failed : Boolean;

   procedure AddRange(const minChar, maxChar : String);
   var
      c, minC, maxC : Integer;
   begin
      if (Length(minChar) <> 1) then Exit;
      if (Length(maxChar) <> 1) then Exit;
      minC := Ord(minChar[1]);
      maxC := Ord(maxChar[1]);
      if minC > cMaxChar then Exit;
      if maxC > cMaxChar then Exit;

      if Length(Result.FMap) <= maxC then
         SetLength(Result.FMap, maxC+1);
      for c := minC to maxC do
         Result.FMap[c] := True;

      failed := False;
   end;

   procedure AddCharacter(const s : String);
   begin
      AddRange(s, s);
   end;

var
   cc : TRefCountedObject;
   lowVal, highVal : String;
   rcc : TRangeCaseCondition;
begin
   Result := TCharacterInOpExpr.Create(context, Left);
   failed := True;
   for cc in conditionsList do begin
      failed := True;
      if cc is TCompareConstStringCaseCondition then begin
         AddCharacter(TCompareConstStringCaseCondition(cc).Value)
      end else if cc is TRangeCaseCondition then begin
         rcc := TRangeCaseCondition(cc);
         if     rcc.FromExpr.IsConstant and rcc.ToExpr.IsConstant
            and rcc.FromExpr.Typ.IsOfType(context.TypString)
            and rcc.ToExpr.Typ.IsOfType(context.TypString) then begin

            rcc.FromExpr.EvalAsString(context.Execution, lowVal);
            rcc.ToExpr.EvalAsString(context.Execution, highVal);
            AddRange(lowVal, highVal);
         end;
      end;
      if failed then break;
   end;

   if failed then begin
      Result.FLeft := nil;
      FreeAndNil(Result);
   end else Result.FMapHigh := High(Result.FMap);
end;

// EvalAsBoolean
//
function TCharacterInOpExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   value : String;
   c : Integer;
begin
   FLeft.EvalAsString(exec, value);
   if value <> '' then begin
      c := Ord(PChar(Pointer(value))^);
      Result := (c <= FMapHigh) and FMap[c];
   end else Result := False;
end;

// ------------------
// ------------------ TIntegerInOpExpr ------------------
// ------------------

// EvalAsBoolean
//
function TIntegerInOpExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   i : Integer;
   value : Int64;
   cc : TCaseCondition;
begin
   value:=FLeft.EvalAsInteger(exec);
   for i:=0 to FCaseConditions.Count-1 do begin
      cc:=TCaseCondition(FCaseConditions.List[i]);
      if cc.IntegerIsTrue(value) then
         Exit(True);
   end;
   Result:=False;
end;

// ------------------
// ------------------ TStringInOpStaticSetExpr ------------------
// ------------------

// Destroy
//
destructor TStringInOpStaticSetExpr.Destroy;
begin
   inherited;
   FSortedStrings.Free;
end;

// Prepare
//
procedure TStringInOpStaticSetExpr.Prepare;
var
   i : Integer;
   cc : TCompareConstStringCaseCondition;
begin
   FSortedStrings := TUnicodeStringList.Create;
   for i:=0 to FCaseConditions.Count-1 do begin
      cc:=(FCaseConditions.List[i] as TCompareConstStringCaseCondition);
      FSortedStrings.Add(UnicodeString(cc.Value));
   end;
   FSortedStrings.Sorted := True;
end;

// EvalAsBoolean
//
function TStringInOpStaticSetExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   i : Integer;
   value : UnicodeString;
begin
   FLeft.EvalAsUnicodeString(exec, value);
   Result := FSortedStrings.Find(value, i);
end;

// ------------------
// ------------------ TBitwiseInOpExpr ------------------
// ------------------

// EvalAsBoolean
//
function TBitwiseInOpExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   i : Int64;
begin
   i:=Expr.EvalAsInteger(exec);
   Result:=    (UInt64(i)<UInt64(32))
           and (((1 shl i) and Mask)<>0);
end;

// ------------------
// ------------------ TEnumerationElementNameExpr ------------------
// ------------------

// Create
//
constructor TEnumerationElementNameExpr.Create(context : TdwsBaseSymbolsContext; const aScriptPos : TScriptPos; expr : TTypedExpr);
begin
   inherited;
   Assert(expr.Typ is TEnumerationSymbol);
end;

// EvalElement
//
function TEnumerationElementNameExpr.EvalElement(exec : TdwsExecution) : TElementSymbol;
var
   enumeration : TEnumerationSymbol;
begin
   enumeration:=TEnumerationSymbol(Expr.Typ);
   Result:=enumeration.ElementByValue(Expr.EvalAsInteger(exec));
end;

// EvalAsString
//
procedure TEnumerationElementNameExpr.EvalAsString(exec : TdwsExecution; var result : String);
var
   element : TElementSymbol;
begin
   element:=EvalElement(exec);
   if element<>nil then
      Result:=element.Name
   else Result:='?';
end;

// ------------------
// ------------------ TEnumerationElementQualifiedNameExpr ------------------
// ------------------

// EvalAsString
//
procedure TEnumerationElementQualifiedNameExpr.EvalAsString(exec : TdwsExecution; var result : String);
var
   element : TElementSymbol;
begin
   element:=EvalElement(exec);
   if element<>nil then
      Result:=element.QualifiedName
   else Result:=TEnumerationSymbol(Expr.Typ).Name+'.?';
end;

// ------------------
// ------------------ TAssertExpr ------------------
// ------------------

// Create
//
constructor TAssertExpr.Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos; condExpr, msgExpr : TTypedExpr);
begin
   inherited Create(aScriptPos);
   FCond:=condExpr;
   FMessage:=msgExpr;
end;

// Destroy
//
destructor TAssertExpr.Destroy;
begin
   FCond.Free;
   FMessage.Free;
   inherited;
end;

// EvalNoResult
//
procedure TAssertExpr.EvalNoResult(exec : TdwsExecution);

   procedure Triggered;
   var
      msg : String;
   begin
      if FMessage<>nil then begin
         FMessage.EvalAsString(exec, msg);
         msg:=' : '+msg;
      end else msg:='';
      (exec as TdwsProgramExecution).RaiseAssertionFailed(Self, msg, FScriptPos);
   end;

begin
   if not FCond.EvalAsBoolean(exec) then
      Triggered;
end;

// Optimize
//
function TAssertExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   Result:=Self;
   if FCond.IsConstant and FCond.EvalAsBoolean(context.Execution) then begin
      Result:=TNullExpr.Create(FScriptPos);
      Orphan(context);
   end;
end;

// GetSubExpr
//
function TAssertExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   if i=0 then
      Result:=FCond
   else Result:=FMessage;
end;

// GetSubExprCount
//
function TAssertExpr.GetSubExprCount : Integer;
begin
   Result:=2;
end;

// ------------------
// ------------------ TAssignedInstanceExpr ------------------
// ------------------

// EvalAsBoolean
//
function TAssignedInstanceExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   obj : IScriptObj;
begin
   FExpr.EvalAsScriptObj(exec, obj);
   Result:=(obj<>nil);
end;

// ------------------
// ------------------ TAssignedInterfaceExpr ------------------
// ------------------

// EvalAsBoolean
//
function TAssignedInterfaceExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   intf : IScriptObjInterface;
begin
   FExpr.EvalAsScriptObjInterface(exec, intf);
   Result:=(intf<>nil);
end;

// ------------------
// ------------------ TAssignedMetaClassExpr ------------------
// ------------------

// EvalAsBoolean
//
function TAssignedMetaClassExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
begin
   Result:=(FExpr.EvalAsInteger(exec)<>0);
end;

// ------------------
// ------------------ TAssignedFuncPtrExpr ------------------
// ------------------

// EvalAsBoolean
//
function TAssignedFuncPtrExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   v : Variant;
begin
   FExpr.EvalAsVariant(exec, v);
   Result:=(IUnknown(v)<>nil);
end;

// ------------------
// ------------------ TOrdExpr ------------------
// ------------------

// EvalAsInteger
//
function TOrdExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
var
   v : Variant;
begin
   Result:=0;
   FExpr.EvalAsVariant(exec, v);
   case VariantType(v) of
      varSmallInt, varInteger, varShortInt, varByte, varWord, varLongWord, varInt64, varUInt64 :
         Result:=v;
      varBoolean :
         if v then
            Result:=1
         else Result:=0;
      varSingle :
         Result := Round(TVarData(v).VSingle);
      varDouble :
         Result := Round(TVarData(v).VDouble);
      varCurrency :
         Result := Round(TVarData(v).VCurrency);
      varString, {$ifndef FPC}varUString,{$endif} varOleStr :
         Result := Ord(FirstWideCharOfString(v));
   else
      RaiseScriptError(exec, EScriptError.Create(RTE_OrdinalExpected));
   end;
end;

{ TOrdIntExpr }

// EvalAsInteger
//
function TOrdIntExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=FExpr.EvalAsInteger(exec);
end;

{ TOrdBoolExpr }

// EvalAsInteger
//
function TOrdBoolExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=Ord(FExpr.EvalAsBoolean(exec));
end;

{ TOrdStrExpr }

// EvalAsInteger
//
function TOrdStrExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
var
   s : String;
   charCode : Integer;
   surrogate : Integer;
begin
   FExpr.EvalAsString(exec, s);
   if s='' then
      charCode:=0
   else begin
      charCode:=Ord(s[1]);
      case charCode of
         $D800..$DBFF : if (Length(s)>1) then begin
            surrogate:=Ord(s[2]);
            case surrogate of
               $DC00..$DFFF :
                  charCode:=(charCode-$D800)*$400+(surrogate-$DC00)+$10000;
            end;
         end;
      end;
   end;
   Result:=charCode;
end;

// ------------------
// ------------------ TObjCmpEqualExpr ------------------
// ------------------

// EvalAsBoolean
//
function TObjCmpEqualExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   iLeft, iRight : IScriptObj;
begin
   FLeft.EvalAsScriptObj(exec, iLeft);
   FRight.EvalAsScriptObj(exec, iRight);
   Result:=(iLeft=iRight);
end;

// ------------------
// ------------------ TObjCmpNotEqualExpr ------------------
// ------------------

// EvalAsBoolean
//
function TObjCmpNotEqualExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   iLeft, iRight : IScriptObj;
begin
   FLeft.EvalAsScriptObj(exec, iLeft);
   FRight.EvalAsScriptObj(exec, iRight);
   Result:=(iLeft<>iRight);
end;

// ------------------
// ------------------ TIntfCmpExpr ------------------
// ------------------

// EvalAsBoolean
//
function TIntfCmpExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   iLeft, iRight : IScriptObjInterface;
begin
   FLeft.EvalAsScriptObjInterface(exec, iLeft);
   FRight.EvalAsScriptObjInterface(exec, iRight);
   Result:=(iLeft=iRight);
end;

// ------------------
// ------------------ TNegVariantExpr ------------------
// ------------------

// EvalAsVariant
//
procedure TNegVariantExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
begin
   Expr.EvalAsVariant(exec, Result);
   Result:=-Result;
end;

// ------------------
// ------------------ TNegIntExpr ------------------
// ------------------

// EvalAsInteger
//
function TNegIntExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=-FExpr.EvalAsInteger(exec);
end;

// ------------------
// ------------------ TNegFloatExpr ------------------
// ------------------

// EvalAsFloat
//
function TNegFloatExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   Result:=-FExpr.EvalAsFloat(exec);
end;

// ------------------
// ------------------ TAddVariantExpr ------------------
// ------------------

// EvalAsVariant
//
procedure TAddVariantExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   lv, rv : Variant;
begin
   FLeft.EvalAsVariant(exec, lv);
   FRight.EvalAsVariant(exec, rv);
   Result:=lv+rv;
end;

// ------------------
// ------------------ TAddStrExpr ------------------
// ------------------

// EvalAsString
//
procedure TAddStrExpr.EvalAsString(exec : TdwsExecution; var result : String);
var
   buf : String;
begin
   FLeft.EvalAsString(exec, Result);
   FRight.EvalAsString(exec, buf);
   Result:=Result+buf;
end;

// Optimize
//
function TAddStrExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   if FRight.InheritsFrom(TConstStringExpr) then begin
      Result := TAddStrConstExpr.Create(context, ScriptPos, ttPLUS, FLeft, FRight);
      FLeft := nil;
      FRight := nil;
      Free;
   end else Result := Self;
end;

// ------------------
// ------------------ TAddStrConstExpr ------------------
// ------------------

// EvalAsString
//
procedure TAddStrConstExpr.EvalAsString(exec : TdwsExecution; var result : String);
begin
   FLeft.EvalAsString(exec, Result);
   Result:=Result+(FRight as TConstStringExpr).Value;
end;

// ------------------
// ------------------ TAddIntExpr ------------------
// ------------------

// EvalAsInteger
//
function TAddIntExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=FLeft.EvalAsInteger(exec)+FRight.EvalAsInteger(exec);
end;

// EvalAsFloat
//
function TAddIntExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   Result:=FLeft.EvalAsInteger(exec)+FRight.EvalAsInteger(exec);
end;

// ------------------
// ------------------ TAddFloatExpr ------------------
// ------------------

// EvalAsFloat
//
function TAddFloatExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   Result:=FLeft.EvalAsFloat(exec)+FRight.EvalAsFloat(exec);
end;

// Optimize
//
function TAddFloatExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   Result:=inherited Optimize(context);
   if     (Result=Self)
      and (Left.ClassType=TAddFloatExpr)
      and (TAddFloatExpr(Left).Right.ClassType<>TAddFloatExpr) then begin

      Result:=Left;
      Left:=TAddFloatExpr(Result).Right;
      TAddFloatExpr(Result).Right:=Self;

   end;
end;

// ------------------
// ------------------ TSubVariantExpr ------------------
// ------------------

// EvalAsVariant
//
procedure TSubVariantExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   lv, rv : Variant;
begin
   FLeft.EvalAsVariant(exec, lv);
   FRight.EvalAsVariant(exec, rv);
   Result:=lv-rv;
end;

// ------------------
// ------------------ TSubIntExpr ------------------
// ------------------

// EvalAsInteger
//
function TSubIntExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=FLeft.EvalAsInteger(exec)-FRight.EvalAsInteger(exec);
end;

// EvalAsFloat
//
function TSubIntExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   Result:=FLeft.EvalAsInteger(exec)-FRight.EvalAsInteger(exec);
end;

// ------------------
// ------------------ TSubFloatExpr ------------------
// ------------------

// EvalAsFloat
//
function TSubFloatExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   Result:=FLeft.EvalAsFloat(exec)-FRight.EvalAsFloat(exec);
end;

// ------------------
// ------------------ TMultVariantExpr ------------------
// ------------------

// EvalAsVariant
//
procedure TMultVariantExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   lv, rv : Variant;
begin
   FLeft.EvalAsVariant(exec, lv);
   FRight.EvalAsVariant(exec, rv);
   VarCopySafe(Result, lv*rv);
end;

// ------------------
// ------------------ TMultIntExpr ------------------
// ------------------

// EvalAsInteger
//
function TMultIntExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=FLeft.EvalAsInteger(exec)*FRight.EvalAsInteger(exec);
end;

// EvalAsFloat
//
function TMultIntExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   Result:=FLeft.EvalAsInteger(exec)*FRight.EvalAsInteger(exec);
end;

// Optimize
//
function TMultIntExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
var
   mip : TMultIntPow2Expr;
   n : Integer;
begin
   if Left.SameDataExpr(Right) then begin
      Result := TSqrIntExpr.Create(context, ScriptPos, FLeft);
      FLeft := nil;
      Orphan(context);
   end else if FLeft.IsConstant then begin
      if FRight.IsConstant then
         Result:=inherited
      else begin
         n:=WhichPowerOfTwo(FLeft.EvalAsInteger(context.Execution));
         if n>=1 then begin
            mip:=TMultIntPow2Expr.Create(context, ScriptPos, FRight);
            mip.FShift:=n-1;
            Result:=mip;
            FRight:=nil;
            Orphan(context);
         end else Result:=Self;
      end;
   end else if FRight.IsConstant then begin
      n:=WhichPowerOfTwo(FRight.EvalAsInteger(context.Execution));
      if n>=1 then begin
         mip:=TMultIntPow2Expr.Create(context, ScriptPos, FLeft);
         mip.FShift:=n-1;
         Result:=mip;
         FLeft:=nil;
         Orphan(context);
      end else Result:=Self;
   end else Result:=Self;
end;

// ------------------
// ------------------ TMultIntPow2Expr ------------------
// ------------------

// EvalAsInteger
//
function TMultIntPow2Expr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=Expr.EvalAsInteger(exec)*(Int64(2) shl FShift);
end;

// ------------------
// ------------------ TMultFloatExpr ------------------
// ------------------

// EvalAsFloat
//
function TMultFloatExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   Result:=FLeft.EvalAsFloat(exec)*FRight.EvalAsFloat(exec);
end;

// Optimize
//
function TMultFloatExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   if Left.SameDataExpr(Right) then begin
      Result:=TSqrFloatExpr.Create(context, ScriptPos, FLeft);
      FLeft:=nil;
      Orphan(context);
      Exit;
   end;
   Result:=inherited;
end;

// ------------------
// ------------------ TSqrIntExpr ------------------
// ------------------

// EvalAsInteger
//
function TSqrIntExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=FExpr.EvalAsInteger(exec);
   Result:=Result*Result;
end;

// ------------------
// ------------------ TSqrFloatExpr ------------------
// ------------------

// EvalAsFloat
//
function TSqrFloatExpr.EvalAsFloat(exec : TdwsExecution) : Double;
{$if Defined(WIN32_ASM)}
asm
   mov   eax, [eax].FExpr
   mov   ecx, [eax]
   call  [ecx+VMTOFFSET EvalAsFloat]
   fmul  st(0), st(0)
{$else}
begin
   Result:=Sqr(FExpr.EvalAsFloat(exec));
{$ifend}
end;

// ------------------
// ------------------ TDivideExpr ------------------
// ------------------

// EvalAsFloat
//
function TDivideExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   Result := FLeft.EvalAsFloat(exec) / FRight.EvalAsFloat(exec);
end;

// Optimize
//
function TDivideExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   if FRight is TDivideExpr then begin
      Result:=TMultFloatExpr.Create(context, ScriptPos, ttTIMES, Left, Right);
      TDivideExpr(Right).Swap;
      FLeft:=nil;
      FRight:=nil;
      Orphan(context);
      Result:=Result.Optimize(context);
   end else Result:=inherited Optimize(context);
end;

// ------------------
// ------------------ TModFloatExpr ------------------
// ------------------

// EvalAsFloat
//
function TModFloatExpr.EvalAsFloat(exec : TdwsExecution) : Double;

   function fmod(f, d : Double) : Double;
{$if Defined(WIN32_ASM)}
   asm
      fld d
      fld f
   @@loop:
      fprem
      fnstsw
      sahf
      jp @@loop
      ffree st(1)
   end;
{$else}
   begin
      Result := Frac(f / d) * d;
   end;
{$ifend}

begin
   Result := fmod(Left.EvalAsFloat(exec), Right.EvalAsFloat(exec));
end;

// ------------------
// ------------------ TDivExpr ------------------
// ------------------

// TDivExpr
//
function TDivExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   try
      Result:=FLeft.EvalAsInteger(exec) div FRight.EvalAsInteger(exec);
   except
      exec.SetScriptError(Self);
      raise;
   end;
end;

// Optimize
//
function TDivExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   Result:=inherited Optimize(context);
   if (Result=Self) and (FRight.ClassType=TConstIntExpr) then begin
      if TConstIntExpr(Right).Value=0 then
         context.Msgs.AddCompilerError(FScriptPos, CPE_DivisionByZero);
      Result:=TDivConstExpr.Create(context, FScriptPos, ttDIV, Left, Right);
      Left:=nil;
      Right:=nil;
      Orphan(context);
   end;
end;

// ------------------
// ------------------ TDivConstExpr ------------------
// ------------------

// EvalAsInteger
//
function TDivConstExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=FLeft.EvalAsInteger(exec) div TConstIntExpr(FRight).Value;
end;

// ------------------
// ------------------ TModExpr ------------------
// ------------------

// EvalAsInteger
//
function TModExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   try
      Result:=FLeft.EvalAsInteger(exec) mod FRight.EvalAsInteger(exec);
   except
      exec.SetScriptError(Self);
      raise;
   end;
end;

// Optimize
//
function TModExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   Result:=inherited Optimize(context);
   if (Result=Self) and (FRight.ClassType=TConstIntExpr) then begin
      if TConstIntExpr(Right).Value=0 then
         context.Msgs.AddCompilerError(FScriptPos, CPE_DivisionByZero);
      Result:=TModConstExpr.Create(context, FScriptPos, ttMOD, Left, Right);
      Left:=nil;
      Right:=nil;
      Orphan(context);
   end;
end;

// ------------------
// ------------------ TModConstExpr ------------------
// ------------------

// EvalAsInteger
//
function TModConstExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=FLeft.EvalAsInteger(exec) mod TConstIntExpr(FRight).Value;
end;

// ------------------
// ------------------ TNotBoolExpr ------------------
// ------------------

// EvalAsBoolean
//
function TNotBoolExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
begin
   Result:=not FExpr.EvalAsBoolean(exec);
end;

// ------------------
// ------------------ TNotIntExpr ------------------
// ------------------

// EvalAsInteger
//
function TNotIntExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=not FExpr.EvalAsInteger(exec);
end;

// ------------------
// ------------------ TNotVariantExpr ------------------
// ------------------

// EvalAsVariant
//
procedure TNotVariantExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
begin
   FExpr.EvalAsVariant(exec, Result);
   case VariantType(Result) of
      varBoolean :
         TVarData(Result).VBoolean := not TVarData(Result).VBoolean;
      varInt64 :
         TVarData(Result).VInt64 := not TVarData(Result).VInt64;
   else
      Result := not VariantToBool(Result);
   end;
end;

{ TIntAndExpr }

function TIntAndExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result := FLeft.EvalAsInteger(exec) and FRight.EvalAsInteger(exec);
end;

{ TBoolAndExpr }

function TBoolAndExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
begin
   Result := Left.EvalAsBoolean(exec) and Right.EvalAsBoolean(exec);
end;

// Optimize
//
function TBoolAndExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   Result:=inherited Optimize(context);
   if Result.ClassType=TBoolAndExpr then begin
      if Left.IsConstant then begin
         if Left.EvalAsBoolean(context.Execution) then begin
            Result:=Right;
            Right:=nil;
         end else begin
            Result := TConstBooleanExpr.Create(context.TypBoolean, False)
         end;
         Orphan(context);
      end else if Right.IsConstant then begin
         if Right.EvalAsBoolean(context.Execution) then begin
            Result:=Left;
            Left:=nil;
         end else begin
            Result := TConstBooleanExpr.Create(context.TypBoolean, False)
         end;
         Orphan(context);
      end;
   end;
end;

{ TVariantAndExpr }

// EvalAsVariant
//
procedure TVariantAndExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   leftVal, rightVal : Variant;
begin
   Left.EvalAsVariant(exec, leftVal);
   Right.EvalAsVariant(exec, rightVal);
   Result:=leftVal and rightVal;
end;

{ TIntOrExpr }

function TIntOrExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result := FLeft.EvalAsInteger(exec) or FRight.EvalAsInteger(exec);
end;

{ TBoolOrExpr }

function TBoolOrExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
begin
   Result := Left.EvalAsBoolean(exec) or Right.EvalAsBoolean(exec);
end;

// Optimize
//
function TBoolOrExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   Result:=inherited Optimize(context);
   if Result.ClassType=TBoolOrExpr then begin
      if Left.IsConstant then begin
         if Left.EvalAsBoolean(context.Execution) then begin
            Result := TConstBooleanExpr.Create(context.TypBoolean, True)
         end else begin
            Result:=Right;
            Right:=nil;
         end;
         Orphan(context);
      end else if Right.IsConstant then begin
         if Right.EvalAsBoolean(context.Execution) then begin
            Result := TConstBooleanExpr.Create(context.TypBoolean, True)
         end else begin
            Result:=Left;
            Left:=nil;
         end;
         Orphan(context);
      end;
   end;
end;

{ TVariantOrExpr }

// EvalAsVariant
//
procedure TVariantOrExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   leftVal, rightVal : Variant;
begin
   Left.EvalAsVariant(exec, leftVal);
   Right.EvalAsVariant(exec, rightVal);
   Result:=leftVal or rightVal;
end;

{ TIntXorExpr }

function TIntXorExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result := FLeft.EvalAsInteger(exec) xor FRight.EvalAsInteger(exec);
end;

{ TBoolXorExpr }

function TBoolXorExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
begin
   Result := FLeft.EvalAsBoolean(exec) xor FRight.EvalAsBoolean(exec);
end;

{ TVariantXorExpr }

// EvalAsVariant
//
procedure TVariantXorExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   leftVal, rightVal : Variant;
begin
   Left.EvalAsVariant(exec, leftVal);
   Right.EvalAsVariant(exec, rightVal);
   VarCopySafe(Result, leftVal xor rightVal);
end;

// ------------------
// ------------------ TBoolImpliesExpr ------------------
// ------------------

// EvalAsBoolean
//
function TBoolImpliesExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
begin
   Result:=(not FLeft.EvalAsBoolean(exec)) or FRight.EvalAsBoolean(exec);
end;

// ------------------
// ------------------ TShiftExpr ------------------
// ------------------

// Optimize
//
function TShiftExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   if Right.IsConstant and (Right.EvalAsInteger(context.Execution)=0) then begin
      Result:=Left;
      FLeft:=nil;
      Orphan(context);
   end else Result:=Self;
end;

// ------------------
// ------------------ TShlExpr ------------------
// ------------------

// EvalAsInteger
//
function TShlExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result := FLeft.EvalAsInteger(exec) shl FRight.EvalAsInteger(exec);
end;

// ------------------
// ------------------ TShrExpr ------------------
// ------------------

// EvalAsInteger
//
function TShrExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result := FLeft.EvalAsInteger(exec) shr FRight.EvalAsInteger(exec);
end;

// ------------------
// ------------------ TSarExpr ------------------
// ------------------

// EvalAsInteger
//
function TSarExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
var
   left, right : Int64;
begin
   left:=FLeft.EvalAsInteger(exec);
   right:=FRight.EvalAsInteger(exec);
   if right=0 then
      Result:=left
   else if right>63 then
      if left<0 then
         Result:=-1
      else Result:=0
   else if left>=0 then
      Result:=left shr right
   else Result:=(left shr right) or (Int64(-1) shl (64-right));
end;

// ------------------
// ------------------ TStringInStringExpr ------------------
// ------------------

// EvalAsBoolean
//
function TStringInStringExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   leftStr, rightStr : String;
begin
   Left.EvalAsString(exec, leftStr);
   Right.EvalAsString(exec, rightStr);
   Result:=StrContains(rightStr, leftStr);
end;

// Optimize
//
function TStringInStringExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   if (Left is TStrVarExpr) and (Right is TConstStringExpr) then begin
      Result:=TVarStringInConstStringExpr.Create(context, ScriptPos, ttIN, Left, Right);
      Left:=nil;
      Right:=nil;
      Orphan(context);
   end else if (Left is TConstStringExpr) and (Right is TStrVarExpr) then begin
      Result:=TConstStringInVarStringExpr.Create(context, ScriptPos, ttIN, Left, Right);
      Left:=nil;
      Right:=nil;
      Orphan(context);
   end else Result:=inherited;
end;

// ------------------
// ------------------ TVarStringInConstStringExpr ------------------
// ------------------

// EvalAsBoolean
//
function TVarStringInConstStringExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
begin
   Result:=StrContains(TConstStringExpr(Right).Value,
                       exec.Stack.PointerToStringValue_BaseRelative(TStrVarExpr(Left).StackAddr)^);
end;

// ------------------
// ------------------ TConstStringInVarStringExpr ------------------
// ------------------

// EvalAsBoolean
//
function TConstStringInVarStringExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
begin
   Result:=StrContains(exec.Stack.PointerToStringValue_BaseRelative(TStrVarExpr(Right).StackAddr)^,
                       TConstStringExpr(Left).Value);
end;

// ------------------
// ------------------ TCoalesceExpr ------------------
// ------------------

// EvalAsVariant
//
procedure TCoalesceExpr.EvalAsVariant(exec : TdwsExecution; var result : Variant);
var
   i : Int64;
begin
   Left.EvalAsVariant(exec, result);
   case VariantType(result) of
      varEmpty, varNull :
         ;
      varSmallint, varShortInt, varInteger,
      varByte, varWord, varLongWord,
      varInt64, varUInt64 : begin
         i:=result;
         if i<>0 then Exit;
      end;
      varSingle, varCurrency, varDouble, varDate :
         if Double(Result)<>0 then Exit;
      varString{$ifndef FPC}, varUString{$endif} :
         if TVarData(result).VString<>nil then Exit;
      varUnknown : begin
         if not CoalesceableIsFalsey(IUnknown(TVarData(result).VUnknown)) then Exit;
      end;
      varDispatch :
         if TVarData(result).VDispatch<>nil then Exit;
      varOleStr : begin
         if TVarData(result).VOleStr<>nil then Exit;
         if TVarData(result).VOleStr^<>#0 then Exit;
      end;
      varBoolean :
         if TVarData(result).VBoolean then Exit;
   else
      Exit;
   end;
   Right.EvalAsVariant(exec, result);
end;

// ------------------
// ------------------ TCoalesceStrExpr ------------------
// ------------------

// EvalAsString
//
procedure TCoalesceStrExpr.EvalAsString(exec : TdwsExecution; var result : String);
begin
   Left.EvalAsString(exec, result);
   if result='' then
      Right.EvalAsString(exec, result);
end;

// Optimize
//
function TCoalesceStrExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
var
   s : String;
begin
   if Left.IsConstant then begin
      Left.EvalAsString(context.Execution, s);
      if s='' then begin
         Result:=Right;
         FRight:=nil;
      end else begin
         Result:=Left;
         FLeft:=nil;
      end;
      Orphan(context);
      Exit;
   end else Result:=inherited Optimize(context);
end;

// ------------------
// ------------------ TCoalesceIntExpr ------------------
// ------------------

// EvalAsInteger
//
function TCoalesceIntExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result := Left.EvalAsInteger(exec);
   if Result = 0 then
      Result := Right.EvalAsInteger(exec);

end;

// Optimize
//
function TCoalesceIntExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
var
   i : Int64;
begin
   if Left.IsConstant then begin
      i := Left.EvalAsInteger(context.Execution);
      if i = 0 then begin
         Result := Right;
         FRight := nil;
      end else begin
         Result := Left;
         FLeft := nil;
      end;
      Orphan(context);
      Exit;
   end else Result := inherited Optimize(context);
end;

// ------------------
// ------------------ TCoalesceFloatExpr ------------------
// ------------------

// EvalAsFloat
//
function TCoalesceFloatExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   Result := Left.EvalAsFloat(exec);
   if Result = 0 then
      Result := Right.EvalAsFloat(exec);
end;

// Optimize
//
function TCoalesceFloatExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
var
   f : Double;
begin
   if Left.IsConstant then begin
      f := Left.EvalAsFloat(context.Execution);
      if f = 0 then begin
         Result := Right;
         FRight := nil;
      end else begin
         Result := Left;
         FLeft := nil;
      end;
      Orphan(context);
      Exit;
   end else Result := inherited Optimize(context);
end;

// ------------------
// ------------------ TCoalesceClassExpr ------------------
// ------------------

// Create
//
constructor TCoalesceClassExpr.Create(context : TdwsCompilerContext; const aScriptPos : TScriptPos;
                                      const anOp : TTokenType; aLeft, aRight : TTypedExpr);
begin
   inherited Create(context, aScriptPos, anOp, aLeft, aRight);
   Typ:=aLeft.Typ;
end;

// EvalAsVariant
//
procedure TCoalesceClassExpr.EvalAsVariant(exec : TdwsExecution; var result : Variant);
var
   obj : IScriptObj;
begin
   EvalAsScriptObj(exec, obj);
   result:=IUnknown(obj);
end;

// EvalAsScriptObj
//
procedure TCoalesceClassExpr.EvalAsScriptObj(exec : TdwsExecution; var result : IScriptObj);
begin
   Left.EvalAsScriptObj(exec, result);
   if result=nil then
      Right.EvalAsScriptObj(exec, result);
end;

// ------------------
// ------------------ TCoalesceDynArrayExpr ------------------
// ------------------

// Create
//
constructor TCoalesceDynArrayExpr.Create(context : TdwsCompilerContext; const aScriptPos : TScriptPos;
                                         const anOp : TTokenType; aLeft, aRight : TTypedExpr);
begin
   inherited Create(context, aScriptPos, anOp, aLeft, aRight);
   Typ:=aLeft.Typ;
end;

// EvalAsVariant
//
procedure TCoalesceDynArrayExpr.EvalAsVariant(exec : TdwsExecution; var result : Variant);
var
   a : IScriptDynArray;
begin
   EvalAsScriptDynArray(exec, a);
   result:=IUnknown(a);
end;

// EvalAsScriptDynArray
//
procedure TCoalesceDynArrayExpr.EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray);
begin
   Left.EvalAsScriptDynArray(exec, result);
   if (result=nil) or (result.ArrayLength=0) then
      Right.EvalAsScriptDynArray(exec, result);
end;

// ------------------
// ------------------ TAssignExpr ------------------
// ------------------

constructor TAssignExpr.Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                               left : TDataExpr; right : TTypedExpr);
begin
  inherited Create(aScriptPos);
  FLeft := Left;
  FRight := Right;
  TypeCheckAssign(context);
end;

// Destroy
//
destructor TAssignExpr.Destroy;
begin
   FLeft.Free;
   FRight.Free;
   inherited;
end;

// Orphan
//
procedure TAssignExpr.Orphan(context : TdwsCompilerContext);
begin
   if FLeft = nil then begin
      if FRight <> nil then begin
         FRight.Orphan(context);
         FRight := nil;
      end;
      DecRefCount;
   end else inherited;
end;

// EvalNoResult
//
procedure TAssignExpr.EvalNoResult(exec : TdwsExecution);
begin
   FLeft.AssignExpr(exec, FRight);
end;

// TypeCheckAssign
//
procedure TAssignExpr.TypeCheckAssign(context : TdwsCompilerContext);
var
   rightScriptPos : TScriptPos;
begin
   if (FLeft=nil) or (FRight=nil) then Exit;

   if FRight.ClassType=TArrayConstantExpr then
      TArrayConstantExpr(FRight).Prepare(context, FLeft.Typ.Typ);

   rightScriptPos:=Right.ScriptPos;
   if not rightScriptPos.Defined then
      rightScriptPos:=Self.ScriptPos;

   FRight:=TConvExpr.WrapWithConvCast(context, rightScriptPos,
                                      FLeft.Typ, FRight, CPE_AssignIncompatibleTypes);
end;

// Optimize
//
function TAssignExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
type
   TCombinedOp = record
      Op : TBinaryOpExprClass; Comb : TOpAssignExprClass;
   end;
const
   cCombinedOps : array [0..6] of TCombinedOp = (
      (Op: TAddIntExpr;    Comb: TPlusAssignIntExpr),
      (Op: TSubIntExpr;    Comb: TMinusAssignIntExpr),
      (Op: TMultIntExpr;   Comb: TMultAssignIntExpr),
      (Op: TAddFloatExpr;  Comb: TPlusAssignFloatExpr),
      (Op: TSubFloatExpr;  Comb: TMinusAssignFloatExpr),
      (Op: TMultFloatExpr; Comb: TMultAssignFloatExpr),
      (Op: TDivideExpr;    Comb: TDivideAssignExpr)
   );
var
   i : Integer;
   leftVarExpr : TVarExpr;
   addIntExpr : TAddIntExpr;
   addStrExpr : TAddStrExpr;
   subIntExpr : TSubIntExpr;
   rightClassType : TClass;
begin
   if FRight.IsConstant then begin
      Exit(OptimizeConstAssignment(context));
   end;

   Result:=Self;
   rightClassType := FRight.ClassType;
   if FLeft.InheritsFrom(TVarExpr)then begin
      leftVarExpr := TVarExpr(FLeft);
      if leftVarExpr.ClassType = TIntVarExpr then begin
         if rightClassType = TAddIntExpr then begin
            addIntExpr := TAddIntExpr(FRight);
            if addIntExpr.Left.SameDataExpr(leftVarExpr) then begin
               Result := TIncIntVarExpr.Create(context, FScriptPos, FLeft, addIntExpr.Right);
               FLeft := nil;
               addIntExpr.Right := nil;
               Free;
               Exit;
            end;
         end else if rightClassType=TSubIntExpr then begin
            subIntExpr:=TSubIntExpr(FRight);
            if subIntExpr.Left.SameDataExpr(leftVarExpr) then begin
               Result:=TDecIntVarExpr.Create(context, FScriptPos, FLeft, subIntExpr.Right);
               FLeft:=nil;
               subIntExpr.Right:=nil;
               Free;
               Exit;
            end;
         end;
      end else if leftVarExpr.ClassType=TStrVarExpr then begin
         if (leftVarExpr.DataSym is TClassVarSymbol) and TClassVarSymbol(leftVarExpr.DataSym).OwnerSymbol.IsExternal then begin
            Exit;
         end;
         if rightClassType=TAddStrExpr then begin
            addStrExpr:=TAddStrExpr(FRight);
            if (addStrExpr.Left is TVarExpr) and (addStrExpr.Left.ReferencesVariable(leftVarExpr.DataSym)) then begin
               if addStrExpr.Right.InheritsFrom(TConstStringExpr) then begin
                  Result:=TAppendConstStringVarExpr.Create(context, FScriptPos, FLeft, addStrExpr.Right);
               end else begin
                  Result:=TAppendStringVarExpr.Create(context, FScriptPos, FLeft, addStrExpr.Right);
               end;
               FLeft:=nil;
               addStrExpr.Right:=nil;
               Free;
               Exit;
            end;
         end;
      end;
   end;
   if (Right is TBinaryOpExpr) and Left.SameDataExpr(TBinaryOpExpr(Right).Left) then begin
      for i:=Low(cCombinedOps) to High(cCombinedOps) do begin
         if rightClassType=cCombinedOps[i].Op then begin
            Result:=cCombinedOps[i].Comb.Create(context, FScriptPos, FLeft, TBinaryOpExpr(Right).Right);
            FLeft:=nil;
            TBinaryOpExpr(Right).Right:=nil;
            Free;
            Exit;
         end;
      end;
   end;
end;

// OptimizeConstAssignment
//
function TAssignExpr.OptimizeConstAssignment(context : TdwsCompilerContext) : TNoResultExpr;
var
   stringBuf : String;
begin
   Result:=Self;

   if FLeft.IsOfType(context.TypVariant) then Exit;

   if FRight.IsOfType(context.TypInteger) then begin

      Result:=TAssignConstToIntegerVarExpr.CreateVal(context, FScriptPos, FLeft, FRight.EvalAsInteger(context.Execution));

   end else if FRight.IsOfType(context.TypFloat) then begin

      Result:=TAssignConstToFloatVarExpr.CreateVal(context, FScriptPos, FLeft, FRight.EvalAsFloat(context.Execution));

   end else if FRight.IsOfType(context.TypBoolean) then begin

      Result:=TAssignConstToBoolVarExpr.CreateVal(context, FScriptPos, FLeft, FRight.EvalAsBoolean(context.Execution));

   end else if FRight.IsOfType(context.TypString) then begin

      FRight.EvalAsString(context.Execution, stringBuf);
      Result:=TAssignConstToStringVarExpr.CreateVal(context, FScriptPos, FLeft, stringBuf);

   end else if FRight.IsOfType(context.TypNil) then begin

      if FLeft.Typ.UnAliasedType.ClassType=TClassSymbol then
         Result:=TAssignNilToVarExpr.CreateVal(context, FScriptPos, FLeft)
      else if FLeft.Typ.UnAliasedType.ClassType=TClassOfSymbol then
         Result:=TAssignNilClassToVarExpr.CreateVal(context, FScriptPos, FLeft);

   end;
   if Result<>Self then begin
      FLeft:=nil;
      if FRight <> nil then begin
         FRight.Orphan(context);
         FRight := nil;
      end;
      Free;
   end;
end;

// SpecializeProgramExpr
//
function TAssignExpr.SpecializeProgramExpr(const context : ISpecializationContext) : TProgramExpr;
begin
   Result := CreateAssignExpr(
      CompilerContextFromSpecialization(context), ScriptPos,
      ttASSIGN,
      FLeft.SpecializeDataExpr(context),
      FRight.SpecializeTypedExpr(context)
   );
//
//   Result := TAssignExprClass(ClassType).Create(
//      CompilerContextFromSpecialization(context), ScriptPos,
//      FLeft.SpecializeDataExpr(context),
//      FRight.SpecializeTypedExpr(context)
//      );
end;

// GetSubExpr
//
function TAssignExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   if i=0 then
      Result:=FLeft
   else Result:=FRight;
end;

// GetSubExprCount
//
function TAssignExpr.GetSubExprCount : Integer;
begin
   Result:=2;
end;

// ------------------
// ------------------ TAssignClassOfExpr ------------------
// ------------------

// EvalNoResult
//
procedure TAssignClassOfExpr.EvalNoResult(exec : TdwsExecution);
var
   v : Variant;
   obj : IScriptObj;
begin
   FRight.EvalAsVariant(exec, v);
   if VariantIsOrdinal(v) then
      FLeft.AssignValue(exec, v)
   else begin
      obj:=IScriptObj(IUnknown(v));
      if obj<>nil then
         FLeft.AssignValueAsInteger(exec, Int64(IScriptObj(IUnknown(v)).ClassSym))
      else FLeft.AssignValueAsInteger(exec, 0);
   end;
end;

{ TAssignDataExpr }

constructor TAssignDataExpr.Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                                   left : TDataExpr; right : TTypedExpr);
begin
  inherited Create(context, aScriptPos, Left, Right);
  FSize := FLeft.Typ.Size;
end;

procedure TAssignDataExpr.EvalNoResult(exec : TdwsExecution);
begin
   FLeft.AssignDataExpr(exec, TDataExpr(FRight));
end;

// ------------------
// ------------------ TAssignFuncExpr ------------------
// ------------------

// TypeCheckAssign
//
procedure TAssignFuncExpr.TypeCheckAssign(context : TdwsCompilerContext);
begin
   if not FLeft.Typ.IsCompatible((FRight as TFuncExprBase).FuncSym) then
      context.Msgs.AddCompilerError(ScriptPos, CPE_IncompatibleOperands);
end;

// EvalNoResult
//
procedure TAssignFuncExpr.EvalNoResult(exec : TdwsExecution);
var
   funcPtr : TFuncPointer;
   funcExpr : TFuncExprBase;
begin
   funcExpr:=(FRight as TFuncExprBase);
   funcPtr:=TFuncPointer.Create(exec, funcExpr);
   FLeft.AssignValue(exec, IFuncPointer(funcPtr));
end;

// Optimize
//
function TAssignFuncExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   Result:=Self;
end;

// ------------------
// ------------------ TAssignArrayConstantExpr ------------------
// ------------------

constructor TAssignArrayConstantExpr.Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                                            Left : TDataExpr; Right: TTypedExpr);
begin
  inherited Create(context, aScriptPos, Left, Right as TArrayConstantExpr); // typecheck Right
end;

procedure TAssignArrayConstantExpr.EvalNoResult(exec : TdwsExecution);
var
   dynIntf : IScriptDynArray;
   dynObj : TScriptDynamicArray;
   srcData : TData;
   dataPtr : IDataContext;
begin
   TArrayConstantExpr(FRight).EvalAsTData(exec, srcData);
   if FLeft.Typ.ClassType = TDynamicArraySymbol then begin
      // to dynamic array
      FLeft.EvalAsScriptDynArray(exec, dynIntf);
      if dynIntf=nil then begin
         // first init
         dynObj:=TScriptDynamicArray.CreateNew(TDynamicArraySymbol(FLeft.Typ).Typ);
         FLeft.AssignValueAsScriptDynArray(exec, dynObj);
      end else begin
         dynObj:=TScriptDynamicArray(dynIntf.GetSelf);
      end;
      dynObj.ArrayLength := Length(srcData) div dynObj.ElementSize;
      dynObj.WriteData(srcData, 0, Length(srcData));
   end else begin
      // to static array
      exec.DataContext_Create(srcData, 0, dataPtr);
      FLeft.AssignData(exec, dataPtr);
   end;
end;

// TypeCheckAssign
//
procedure TAssignArrayConstantExpr.TypeCheckAssign(context : TdwsCompilerContext);
var
   leftItemTyp, rightItemTyp : TTypeSymbol;
begin
   if     FLeft.Typ.Typ.IsOfType(context.TypFloat)
      and (Right is TArrayConstantExpr)
      and Right.Typ.Typ.IsOfType(context.TypInteger) then begin
      TArrayConstantExpr(Right).ElementsFromIntegerToFloat(context);
   end;
   if FLeft.Typ is TDynamicArraySymbol then begin
      leftItemTyp := TDynamicArraySymbol(FLeft.Typ).Typ;
      rightItemTyp := TArraySymbol(FRight.Typ).Typ;
      if not (
            leftItemTyp.IsOfType(rightItemTyp)
         or leftItemTyp.IsCompatible(rightItemTyp)
         or leftItemTyp.IsOfType(context.TypVariant)
         or (leftItemTyp.IsPointerType and rightItemTyp.IsOfType(context.TypNil))
         ) then begin
         context.Msgs.AddCompilerErrorFmt(ScriptPos, CPE_AssignIncompatibleTypes,
                                          [Right.Typ.Caption, Left.Typ.Caption]);
      end;
   end else inherited;
end;

// ------------------
// ------------------ TAssignConstDataToVarExpr ------------------
// ------------------

constructor TAssignConstDataToVarExpr.Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                                             Left : TDataExpr; Right: TTypedExpr);
begin
   inherited Create(context, aScriptPos, Left, Right);
   Assert(Left is TVarExpr);
   if Right=nil then
      Assert(ClassType<>TAssignConstDataToVarExpr)
   else Assert(Right is TConstExpr);
end;

procedure TAssignConstDataToVarExpr.EvalNoResult(exec : TdwsExecution);
begin
   TVarExpr(FLeft).AssignData(exec, TConstExpr(FRight).DataPtr[exec]);
end;

// ------------------
// ------------------ TAssignConstExpr ------------------
// ------------------

// TypeCheckAssign
//
procedure TAssignConstExpr.TypeCheckAssign(context : TdwsCompilerContext);
begin
   // nothing, checked during optimize
end;

// Optimize
//
function TAssignConstExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   Result:=Self;
end;

// ------------------
// ------------------ TAssignConstToIntegerVarExpr ------------------
// ------------------

// Create
//
constructor TAssignConstToIntegerVarExpr.CreateVal(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                                                   Left : TDataExpr; const rightValue : Int64);
begin
   inherited Create(context, aScriptPos, Left, nil);
   FRight:=rightValue;
end;

// SpecializeProgramExpr
//
function TAssignConstToIntegerVarExpr.SpecializeProgramExpr(const context : ISpecializationContext) : TProgramExpr;
begin
   Result := TAssignConstToIntegerVarExpr.CreateVal(
      CompilerContextFromSpecialization(context), ScriptPos,
      Left.SpecializeDataExpr(context), FRight
   );
end;

// EvalNoResult
//
procedure TAssignConstToIntegerVarExpr.EvalNoResult(exec : TdwsExecution);
begin
   TVarExpr(FLeft).AssignValueAsInteger(exec, FRight);
end;

// RightValue
//
function TAssignConstToIntegerVarExpr.RightValue : Variant;
begin
   Result:=FRight;
end;

// ------------------
// ------------------ TAssignConstToFloatVarExpr ------------------
// ------------------

// Create
//
constructor TAssignConstToFloatVarExpr.CreateVal(context : TdwsCompilerContext;
      const aScriptPos: TScriptPos; left : TDataExpr; const rightValue : Double);
begin
   inherited Create(context, aScriptPos, left, nil);
   FRight:=rightValue;
end;

// EvalNoResult
//
procedure TAssignConstToFloatVarExpr.EvalNoResult(exec : TdwsExecution);
begin
   TVarExpr(FLeft).AssignValueAsFloat(exec, FRight);
end;

// RightValue
//
function TAssignConstToFloatVarExpr.RightValue : Variant;
begin
   Result:=FRight;
end;

// ------------------
// ------------------ TAssignConstToBoolVarExpr ------------------
// ------------------

// Create
//
constructor TAssignConstToBoolVarExpr.CreateVal(
      context : TdwsCompilerContext;
      const aScriptPos: TScriptPos;
      left : TDataExpr; const rightValue : Boolean);
begin
   inherited Create(context, aScriptPos, left, nil);
   FRight:=rightValue;
end;

// EvalNoResult
//
procedure TAssignConstToBoolVarExpr.EvalNoResult(exec : TdwsExecution);
begin
   TVarExpr(FLeft).AssignValueAsBoolean(exec, FRight);
end;

// RightValue
//
function TAssignConstToBoolVarExpr.RightValue : Variant;
begin
   Result:=FRight;
end;

// ------------------
// ------------------ TAssignConstToStringVarExpr ------------------
// ------------------

// Create
//
constructor TAssignConstToStringVarExpr.CreateVal(
      context : TdwsCompilerContext; const aScriptPos: TScriptPos;
      left : TDataExpr; const rightValue : String);
begin
   inherited Create(context, aScriptPos, Left, nil);
   FRight:=rightValue;
end;

// EvalNoResult
//
procedure TAssignConstToStringVarExpr.EvalNoResult(exec : TdwsExecution);
begin
   TVarExpr(FLeft).AssignValueAsString(exec, FRight);
end;

// RightValue
//
function TAssignConstToStringVarExpr.RightValue : Variant;
begin
   Result:=FRight;
end;

// ------------------
// ------------------ TAssignConstToVariantVarExpr ------------------
// ------------------

// CreateVal
//
constructor TAssignConstToVariantVarExpr.CreateVal(
      context : TdwsCompilerContext; const aScriptPos: TScriptPos;
      left : TDataExpr; const rightValue : Variant);
begin
   inherited Create(context, aScriptPos, Left, nil);
   VarCopySafe(FRight, rightValue);
end;

// EvalNoResult
//
procedure TAssignConstToVariantVarExpr.EvalNoResult(exec : TdwsExecution);
begin
   TVarExpr(FLeft).AssignValue(exec, FRight);
end;

// RightValue
//
function TAssignConstToVariantVarExpr.RightValue : Variant;
begin
   Result:=FRight;
end;

// ------------------
// ------------------ TAssignNilToVarExpr ------------------
// ------------------

// CreateVal
//
constructor TAssignNilToVarExpr.CreateVal(context : TdwsCompilerContext;
   const aScriptPos: TScriptPos; left : TDataExpr);
begin
   inherited Create(context, aScriptPos, left, nil);
end;

// RightValue
//
function TAssignNilToVarExpr.RightValue : Variant;
begin
   VarSetNull(Result);
end;

// EvalNoResult
//
procedure TAssignNilToVarExpr.EvalNoResult(exec : TdwsExecution);
begin
   TVarExpr(FLeft).AssignValueAsScriptObj(exec, nil);
end;

// ------------------
// ------------------ TAssignNilClassToVarExpr ------------------
// ------------------

// EvalNoResult
//
procedure TAssignNilClassToVarExpr.EvalNoResult(exec : TdwsExecution);
begin
   TVarExpr(FLeft).AssignValueAsInteger(exec, 0);
end;

// ------------------
// ------------------ TAssignNilAsResetExpr ------------------
// ------------------

// EvalNoResult
//
procedure TAssignNilAsResetExpr.EvalNoResult(exec : TdwsExecution);
var
   dataPtr : IDataContext;
begin
   TVarExpr(FLeft).GetDataPtr(exec, dataPtr);
   FLeft.Typ.InitDataContext(dataPtr);
end;

// ------------------
// ------------------ TOpAssignExpr ------------------
// ------------------

// Optimize
//
function TOpAssignExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   Result:=Self;
end;

// ------------------
// ------------------ TPlusAssignExpr ------------------
// ------------------

// EvalNoResult
//
procedure TPlusAssignExpr.EvalNoResult(exec : TdwsExecution);
var
   lv, rv : Variant;
begin
   FLeft.EvalAsVariant(exec, lv);
   FRight.EvalAsVariant(exec, rv);
   FLeft.AssignValue(exec, lv+rv);
end;

// ------------------
// ------------------ TPlusAssignIntExpr ------------------
// ------------------

// EvalNoResult
//
procedure TPlusAssignIntExpr.EvalNoResult(exec : TdwsExecution);
begin
   FLeft.AssignValueAsInteger(exec, FLeft.EvalAsInteger(exec) + FRight.EvalAsInteger(exec));
end;

// Optimize
//
function TPlusAssignIntExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   Result:=Self;
   if FLeft is TIntVarExpr then begin
      if FRight.ClassType = TConstIntExpr then begin
         Result := TIncIntVarWithConstExpr.Create(context, FScriptPos, FLeft, FRight);
      end else begin
         Result := TIncIntVarExpr.Create(context, FScriptPos, FLeft, FRight);
      end;
      FLeft := nil;
      FRight := nil;
      Orphan(context);
   end;
end;

// ------------------
// ------------------ TPlusAssignFloatExpr ------------------
// ------------------

// EvalNoResult
//
procedure TPlusAssignFloatExpr.EvalNoResult(exec : TdwsExecution);
begin
   FLeft.AssignValueAsFloat(exec, FLeft.EvalAsFloat(exec)+FRight.EvalAsFloat(exec));
end;

// ------------------
// ------------------ TPlusAssignStrExpr ------------------
// ------------------

// EvalNoResult
//
procedure TPlusAssignStrExpr.EvalNoResult(exec : TdwsExecution);
var
   v1, v2 : String;
begin
   FLeft.EvalAsString(exec, v1);
   FRight.EvalAsString(exec, v2);
   FLeft.AssignValueAsString(exec, v1+v2);
end;

// Optimize
//
function TPlusAssignStrExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   Result:=Self;
   if FLeft is TStrVarExpr then begin
      Result:=TAppendStringVarExpr.Create(context, FScriptPos, FLeft, FRight);
      FLeft:=nil;
      FRight:=nil;
      Orphan(context);
   end;
end;

// ------------------
// ------------------ TMinusAssignExpr ------------------
// ------------------

// EvalNoResult
//
procedure TMinusAssignExpr.EvalNoResult(exec : TdwsExecution);
var
   lv, rv : Variant;
begin
   FLeft.EvalAsVariant(exec, lv);
   FRight.EvalAsVariant(exec, rv);
   FLeft.AssignValue(exec, lv-rv);
end;

// ------------------
// ------------------ TMinusAssignIntExpr ------------------
// ------------------

// EvalNoResult
//
procedure TMinusAssignIntExpr.EvalNoResult(exec : TdwsExecution);
begin
   FLeft.AssignValueAsInteger(exec, FLeft.EvalAsInteger(exec) - FRight.EvalAsInteger(exec));
end;

// Optimize
//
function TMinusAssignIntExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   Result:=Self;
   if FLeft is TIntVarExpr then begin
      Result:=TDecIntVarExpr.Create(context, FScriptPos, FLeft, FRight);
      FLeft:=nil;
      FRight:=nil;
      Orphan(context);
   end;
end;

// ------------------
// ------------------ TMinusAssignFloatExpr ------------------
// ------------------

// EvalNoResult
//
procedure TMinusAssignFloatExpr.EvalNoResult(exec : TdwsExecution);
begin
   FLeft.AssignValueAsFloat(exec, FLeft.EvalAsFloat(exec)-FRight.EvalAsFloat(exec));
end;

// ------------------
// ------------------ TMultAssignExpr ------------------
// ------------------

// EvalNoResult
//
procedure TMultAssignExpr.EvalNoResult(exec : TdwsExecution);
var
   lv, rv : Variant;
begin
   FLeft.EvalAsVariant(exec, lv);
   FRight.EvalAsVariant(exec, rv);
   FLeft.AssignValue(exec, lv*rv);
end;

// ------------------
// ------------------ TMultAssignIntExpr ------------------
// ------------------

// EvalNoResult
//
procedure TMultAssignIntExpr.EvalNoResult(exec : TdwsExecution);
begin
   FLeft.AssignValueAsInteger(exec, FLeft.EvalAsInteger(exec) * FRight.EvalAsInteger(exec));
end;

// ------------------
// ------------------ TMultAssignFloatExpr ------------------
// ------------------

// EvalNoResult
//
procedure TMultAssignFloatExpr.EvalNoResult(exec : TdwsExecution);
begin
   FLeft.AssignValueAsFloat(exec, FLeft.EvalAsFloat(exec)*FRight.EvalAsFloat(exec));
end;

// ------------------
// ------------------ TDivideAssignExpr ------------------
// ------------------

// EvalNoResult
//
procedure TDivideAssignExpr.EvalNoResult(exec : TdwsExecution);
begin
   FLeft.AssignValueAsFloat(exec, FLeft.EvalAsFloat(exec)/FRight.EvalAsFloat(exec));
end;

// ------------------
// ------------------ TIncIntVarExpr ------------------
// ------------------

// EvalNoResult
//
procedure TIncIntVarExpr.EvalNoResult(exec : TdwsExecution);
begin
   TIntVarExpr(FLeft).IncValue(exec, FRight.EvalAsInteger(exec));
end;

// ------------------
// ------------------ TDecIntVarExpr ------------------
// ------------------

// EvalNoResult
//
procedure TDecIntVarExpr.EvalNoResult(exec : TdwsExecution);
begin
   TIntVarExpr(FLeft).IncValue(exec, -FRight.EvalAsInteger(exec));
end;

// ------------------
// ------------------ TIncIntVarWithConstExpr ------------------
// ------------------

// EvalNoResult
//
procedure TIncIntVarWithConstExpr.EvalNoResult(exec : TdwsExecution);
begin
   TIntVarExpr(FLeft).IncValue(exec, TConstIntExpr(FRight).Value);
end;

// ------------------
// ------------------ TAbsIntExpr ------------------
// ------------------

// EvalAsInteger
//
function TAbsIntExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   Result:=Abs(Expr.EvalAsInteger(exec));
end;

// ------------------
// ------------------ TAbsFloatExpr ------------------
// ------------------

// EvalAsFloat
//
function TAbsFloatExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   Result:=Abs(Expr.EvalAsFloat(exec));
end;

// ------------------
// ------------------ TAbsVariantExpr ------------------
// ------------------

// EvalAsVariant
//
procedure TAbsVariantExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
begin
   Expr.EvalAsVariant(exec, Result);
   Result:=Abs(Result);
end;

// ------------------
// ------------------ TAppendStringVarExpr ------------------
// ------------------

// EvalNoResult
//
procedure TAppendStringVarExpr.EvalNoResult(exec : TdwsExecution);
var
   buf : String;
begin
   FRight.EvalAsString(exec, buf);
   TStrVarExpr(FLeft).Append(exec, buf);
end;

// ------------------
// ------------------ TAppendConstStringVarExpr ------------------
// ------------------

// Create
//
constructor TAppendConstStringVarExpr.Create(
      context : TdwsCompilerContext; const aScriptPos: TScriptPos;
      left : TDataExpr; right : TTypedExpr);
begin
   inherited Create(context, aScriptPos, Left, Right);
   FAppendString:=(right as TConstStringExpr).Value;
end;

// EvalNoResult
//
procedure TAppendConstStringVarExpr.EvalNoResult(exec : TdwsExecution);
begin
   TStrVarExpr(FLeft).Append(exec, FAppendString);
end;

// ------------------
// ------------------ TBlockExpr ------------------
// ------------------

// Create
//
constructor TBlockExpr.Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos);
begin
   inherited Create(aScriptPos);
   FTable:=TSymbolTable.Create(context.Table, context.Table.AddrGenerator);
end;

// Destroy
//
destructor TBlockExpr.Destroy;
begin
   FTable.Free;
   inherited;
end;

// Orphan
//
procedure TBlockExpr.Orphan(context : TdwsCompilerContext);
begin
   context.OrphanObject(FTable);
   FTable := nil;
   inherited;
end;

// EvalNoResult
//
procedure TBlockExpr.EvalNoResult(exec : TdwsExecution);
var
   i : Integer;
   expr : PProgramExpr;
begin
   expr:=@FStatements[0];
   try
      for i:=1 to FCount do begin
         exec.DoStep(expr^);
         expr.EvalNoResult(exec);
         if exec.Status<>esrNone then Break;
         Inc(expr);
      end;
   except
      exec.SetScriptError(expr^);
      raise;
   end;
end;

// Optimize
//
function TBlockExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
var
   i : Integer;
begin
   if FTable.HasChildTables then
      Exit(Self);

   for i:=FCount-1 downto 0 do begin
      if FStatements[i].ClassType=TNullExpr then begin
         FStatements[i].Free;
         if i+1<FCount then
            Move(FStatements[i+1], FStatements[i], SizeOf(TNoResultExpr)*(FCount-1-i));
         Dec(FCount);
         ReallocMem(FStatements, FCount*SizeOf(TNoResultExpr));
      end;
   end;

   if FTable.Count=0 then begin
      case FCount of
         0 : Result:=TNullExpr.Create(FScriptPos);
         1 : begin
            Result:=FStatements[0];
            FreeMem(FStatements);
         end;
      else
         case FCount of
            2 : Result:=TBlockExprNoTable2.Create(FScriptPos);
            3 : Result:=TBlockExprNoTable3.Create(FScriptPos);
            4 : Result:=TBlockExprNoTable4.Create(FScriptPos);
         else
            Result:=TBlockExprNoTable.Create(FScriptPos);
         end;
         TBlockExprNoTable(Result).FStatements:=FStatements;
         TBlockExprNoTable(Result).FCount:=FCount;
      end;
      FStatements:=nil;
      FCount:=0;
      Orphan(context);
   end else Result:=Self;
end;

// SpecializeTable
//
procedure TBlockExpr.SpecializeTable(const context : ISpecializationContext; destination : TBlockExprBase);
begin
   context.SpecializeTable(FTable, (destination as TBlockExpr).FTable);
end;

// ------------------
// ------------------ TBlockExprNoTable ------------------
// ------------------

// Orphan
//
procedure TBlockExprNoTable.Orphan(context : TdwsCompilerContext);
begin
   if FCount=0 then
      DecRefCount
   else inherited;
end;

// EvalNoResult
//
procedure TBlockExprNoTable.EvalNoResult(exec : TdwsExecution);
var
   i : Integer;
   iterator : PProgramExpr;
begin
   iterator:=PProgramExpr(FStatements);
   for i:=1 to FCount do begin
      exec.DoStep(iterator^);
      iterator^.EvalNoResult(exec);
      if exec.Status<>esrNone then Break;
      Inc(iterator);
   end;
end;

// ------------------
// ------------------ TBlockExprNoTable2 ------------------
// ------------------

// EvalNoResult
//
procedure TBlockExprNoTable2.EvalNoResult(exec : TdwsExecution);
var
   statements : PProgramExprList;
begin
   statements:=FStatements;
   exec.DoStep(statements[0]);
   statements[0].EvalNoResult(exec);
   if exec.Status<>esrNone then Exit;
   exec.DoStep(statements[1]);
   statements[1].EvalNoResult(exec);
end;

// ------------------
// ------------------ TBlockExprNoTable3 ------------------
// ------------------

// EvalNoResult
//
procedure TBlockExprNoTable3.EvalNoResult(exec : TdwsExecution);
var
   statements : PProgramExprList;
begin
   statements:=FStatements;
   exec.DoStep(statements[0]);
   statements[0].EvalNoResult(exec);
   if exec.Status<>esrNone then Exit;
   exec.DoStep(statements[1]);
   statements[1].EvalNoResult(exec);
   if exec.Status<>esrNone then Exit;
   exec.DoStep(statements[2]);
   statements[2].EvalNoResult(exec);
end;

// ------------------
// ------------------ TBlockExprNoTable4 ------------------
// ------------------

// EvalNoResult
//
procedure TBlockExprNoTable4.EvalNoResult(exec : TdwsExecution);
var
   statements : PProgramExprList;
begin
   statements:=FStatements;
   exec.DoStep(statements[0]);
   statements[0].EvalNoResult(exec);
   if exec.Status<>esrNone then Exit;
   exec.DoStep(statements[1]);
   statements[1].EvalNoResult(exec);
   if exec.Status<>esrNone then Exit;
   exec.DoStep(statements[2]);
   statements[2].EvalNoResult(exec);
   if exec.Status<>esrNone then Exit;
   exec.DoStep(statements[3]);
   statements[3].EvalNoResult(exec);
end;

// ------------------
// ------------------ TIfThenExpr ------------------
// ------------------

// Create
//
constructor TIfThenExpr.Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                               condExpr : TTypedExpr; thenExpr : TProgramExpr);
begin
   inherited Create(aScriptPos);
   FCond:=condExpr;
   FThen:=thenExpr;
end;

// Destroy
//
destructor TIfThenExpr.Destroy;
begin
   FCond.Free;
   FThen.Free;
   inherited;
end;

// EvalNoResult
//
procedure TIfThenExpr.EvalNoResult(exec : TdwsExecution);
begin
   if FCond.EvalAsBoolean(exec) then begin
      exec.DoStep(FThen);
      FThen.EvalNoResult(exec);
   end;
end;

// Orphan
//
procedure TIfThenExpr.Orphan(context : TdwsCompilerContext);
begin
   if FCond <> nil then begin
      FCond.Orphan(context);
      FCond := nil;
   end;
   if FThen <> nil then begin
      FThen.Orphan(context);
      FThen := nil;
   end;
   DecRefCount;
end;

// Optimize
//
function TIfThenExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   Result:=Self;
   if FCond.IsConstant then begin
      if FCond.EvalAsBoolean(context.Execution) then begin
         Result:=FThen;
         FThen:=nil;
      end else Result:=TNullExpr.Create(FScriptPos);
      Orphan(context);
   end;
end;

// SpecializeProgramExpr
//
function TIfThenExpr.SpecializeProgramExpr(const context : ISpecializationContext) : TProgramExpr;
begin
   Result := TIfThenExpr.Create(
      CompilerContextFromSpecialization(context),
      ScriptPos,
      CondExpr.SpecializeBooleanExpr(context),
      ThenExpr.SpecializeProgramExpr(context)
   );
end;

// EnumerateSteppableExprs
//
procedure TIfThenExpr.EnumerateSteppableExprs(const callback : TExprBaseProc);
begin
   callback(ThenExpr);
end;

// GetSubExpr
//
function TIfThenExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   if i=0 then
      Result:=FCond
   else Result:=FThen;
end;

// GetSubExprCount
//
function TIfThenExpr.GetSubExprCount : Integer;
begin
   Result:=2;
end;

// ------------------
// ------------------ TIfThenElseExpr ------------------
// ------------------

// Create
//
constructor TIfThenElseExpr.Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                 condExpr : TTypedExpr; thenExpr, elseExpr : TProgramExpr);
begin
   inherited Create(context, aScriptPos, condExpr, thenExpr);
   FElse:=elseExpr;
end;

// Destroy
//
destructor TIfThenElseExpr.Destroy;
begin
   FElse.Free;
   inherited;
end;

// EvalNoResult
//
procedure TIfThenElseExpr.EvalNoResult(exec : TdwsExecution);
begin
   if FCond.EvalAsBoolean(exec) then begin
      exec.DoStep(FThen);
      FThen.EvalNoResult(exec);
   end else begin
      exec.DoStep(FElse);
      FElse.EvalNoResult(exec);
   end;
end;

// Orphan
//
procedure TIfThenElseExpr.Orphan(context : TdwsCompilerContext);
begin
   if FElse <> nil then begin
      FElse.Orphan(context);
      FElse := nil;
   end;
   inherited;
end;

// Optimize
//
function TIfThenElseExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
var
   bufNoResult : TProgramExpr;
   notExpr : TNotBoolExpr;
begin
   if FCond.IsConstant then begin
      if FCond.EvalAsBoolean(context.Execution) then begin
         Result:=FThen;
         FThen:=nil;
      end else begin
         Result:=FElse;
         FElse:=nil;
      end;
      Orphan(context);
   end else begin
      Result:=Self;
      if FCond is TNotBoolExpr then begin
         notExpr:=TNotBoolExpr(FCond);
         FCond:=notExpr.Expr;
         notExpr.Expr:=nil;
         notExpr.Free;
         bufNoResult:=ElseExpr;
         FElse:=FThen;
         FThen:=bufNoResult;
      end;
   end;
end;

// SpecializeProgramExpr
//
function TIfThenElseExpr.SpecializeProgramExpr(const context : ISpecializationContext) : TProgramExpr;
begin
   Result := TIfThenElseExpr.Create(
      CompilerContextFromSpecialization(context),
      ScriptPos,
      CondExpr.SpecializeTypedExpr(context),
      ThenExpr.SpecializeProgramExpr(context),
      ElseExpr.SpecializeProgramExpr(context)
   );
end;

// EnumerateSteppableExprs
//
procedure TIfThenElseExpr.EnumerateSteppableExprs(const callback : TExprBaseProc);
begin
   callback(ThenExpr);
   callback(ElseExpr);
end;

// GetSubExpr
//
function TIfThenElseExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   if i=2 then
      Result:=FElse
   else Result:=inherited GetSubExpr(i);
end;

// GetSubExprCount
//
function TIfThenElseExpr.GetSubExprCount : Integer;
begin
   Result:=3;
end;

{ TCaseExpr }

destructor TCaseExpr.Destroy;
begin
  FCaseConditions.Clean;
  FValueExpr.Free;
  FElseExpr.Free;
  inherited;
end;

// EvalNoResult
//
procedure TCaseExpr.EvalNoResult(exec : TdwsExecution);
var
   x : Integer;
   value : Variant;
   cc : TCaseCondition;
begin
   FValueExpr.EvalAsVariant(exec, value);
   for x := 0 to FCaseConditions.Count - 1 do begin
      cc:=TCaseCondition(FCaseConditions.List[x]);
      if cc.IsTrue(exec, value) then begin
         exec.DoStep(cc.TrueExpr);
         cc.TrueExpr.EvalNoResult(exec);
         Exit;
      end;
   end;

   if Assigned(FElseExpr) then begin
      exec.DoStep(FElseExpr);
      FElseExpr.EvalNoResult(exec);
   end;
end;

// AddCaseCondition
//
procedure TCaseExpr.AddCaseCondition(cond : TCaseCondition);
begin
   FCaseConditions.Add(cond);
end;

// Optimize
//
function TCaseExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;

   procedure TransferFieldsAndFree(dest : TCaseExpr);
   begin
      dest.FCaseConditions.Assign(FCaseConditions);
      dest.FElseExpr:=FElseExpr;
      dest.FValueExpr:=FValueExpr;
      FCaseConditions.Clear;
      FElseExpr:=nil;
      FValueExpr:=nil;
      Orphan(context);
   end;

var
   cond : array [0..1] of TCompareCaseCondition;
   trueIndex : Integer;
   cse : TCaseStringExpr;
   cie : TCaseIntegerExpr;
begin
   if ValueExpr.Typ.IsOfType(context.TypString) then begin
      if TCaseConditionsHelper.CanOptimizeToTyped(FCaseConditions, TConstStringExpr) then begin
         cse:=TCaseStringExpr.Create(ScriptPos);
         TransferFieldsAndFree(cse);
         Exit(cse);
      end;
   end else if ValueExpr.Typ.IsOfType(context.TypInteger) then begin
      if TCaseConditionsHelper.CanOptimizeToTyped(FCaseConditions, TConstIntExpr) then begin
         cie:=TCaseIntegerExpr.Create(ScriptPos);
         TransferFieldsAndFree(cie);
         Exit(cie);
      end;
   end else if     ValueExpr.Typ.IsOfType(context.TypBoolean)
               and (CaseConditions.Count=2)
               and (CaseConditions.List[0] is TCompareCaseCondition)
               and (CaseConditions.List[1] is TCompareCaseCondition) then begin
      // "case boolean of" to if/then/else
      cond[0]:=TCompareCaseCondition(CaseConditions.List[0]);
      cond[1]:=TCompareCaseCondition(CaseConditions.List[1]);
      if     (cond[0].CompareExpr is TConstBooleanExpr)
         and (cond[0].CompareExpr.ClassType=cond[1].CompareExpr.ClassType)
         and (cond[0].CompareExpr.EvalAsBoolean(context.Execution)=not cond[1].CompareExpr.EvalAsBoolean(context.Execution)) then begin
         if cond[0].CompareExpr.EvalAsBoolean(context.Execution) then
            trueIndex:=0
         else trueIndex:=1;
         Result:=TIfThenElseExpr.Create(context, ScriptPos, ValueExpr,
                                        cond[trueIndex].TrueExpr,
                                        cond[1-trueIndex].TrueExpr);
         ValueExpr:=nil;
         cond[0].TrueExpr:=nil;
         cond[1].TrueExpr:=nil;
         Free;
         Exit;
      end;
   end;
   Result:=Self;
end;

// EnumerateSteppableExprs
//
procedure TCaseExpr.EnumerateSteppableExprs(const callback : TExprBaseProc);
var
   i : Integer;
begin
   for i := 0 to CaseConditions.Count-1 do
      callback(TCaseCondition(CaseConditions.List[i]).TrueExpr);
   callback(ElseExpr);
end;

// GetSubExpr
//
function TCaseExpr.GetSubExpr(i : Integer) : TExprBase;
var
   j : Integer;
   cond : TCaseCondition;
begin
   case i of
      0 : Result:=ValueExpr;
      1 : Result:=ElseExpr;
   else
      Dec(i, 2);
      for j:=0 to FCaseConditions.Count-1 do begin
         cond:=TCaseCondition(FCaseConditions.List[j]);
         if i<cond.GetSubExprCount then
            Exit(cond.GetSubExpr(i));
         Dec(i, cond.GetSubExprCount);
      end;
      Result:=nil;
   end;
end;

// GetSubExprCount
//
function TCaseExpr.GetSubExprCount : Integer;
var
   i : Integer;
begin
   Result:=2;
   for i:=0 to FCaseConditions.Count-1 do
      Inc(Result, TCaseCondition(FCaseConditions.List[i]).GetSubExprCount);
end;

// ------------------
// ------------------ TCaseStringExpr ------------------
// ------------------

// EvalNoResult
//
procedure TCaseStringExpr.EvalNoResult(exec : TdwsExecution);
var
   x : Integer;
   value : String;
   cc : TCaseCondition;
begin
   FValueExpr.EvalAsString(exec, value);
   for x := 0 to FCaseConditions.Count - 1 do begin
      cc:=TCaseCondition(FCaseConditions.List[x]);
      if cc.StringIsTrue(exec, value) then begin
         exec.DoStep(cc.TrueExpr);
         cc.TrueExpr.EvalNoResult(exec);
         Exit;
      end;
   end;

   if Assigned(FElseExpr) then begin
      exec.DoStep(FElseExpr);
      FElseExpr.EvalNoResult(exec);
   end;
end;

// ------------------
// ------------------ TCaseIntegerExpr ------------------
// ------------------

// EvalNoResult
//
procedure TCaseIntegerExpr.EvalNoResult(exec : TdwsExecution);
var
   x : Integer;
   value : int64;
   cc : TCaseCondition;
begin
   value:=FValueExpr.EvalAsInteger(exec);
   for x:=0 to FCaseConditions.Count-1 do begin
      cc:=TCaseCondition(FCaseConditions.List[x]);
      if cc.IntegerIsTrue(value) then begin
         exec.DoStep(cc.TrueExpr);
         cc.TrueExpr.EvalNoResult(exec);
         Exit;
      end;
   end;

   if Assigned(FElseExpr) then begin
      exec.DoStep(FElseExpr);
      FElseExpr.EvalNoResult(exec);
   end;
end;

// ------------------
// ------------------ TCaseCondition ------------------
// ------------------

// Create
//
constructor TCaseCondition.Create(const aPos : TScriptPos);
begin
   FScriptPos:=aPos;
end;

// Destroy
//
destructor TCaseCondition.Destroy;
begin
   FTrueExpr.Free;
   inherited;
end;

// IsOfTypeNumber
//
function TCaseCondition.IsOfTypeNumber(context : TdwsCompilerContext; typ : TTypeSymbol) : Boolean;
begin
   Result:=   typ.IsOfType(context.TypInteger) or typ.IsOfType(context.TypFloat)
           or typ.IsOfType(context.TypVariant)
           or (typ is TEnumerationSymbol);
end;

// ------------------
// ------------------ TCaseConditionsHelper ------------------
// ------------------

// CanOptimizeToTyped
//
class function TCaseConditionsHelper.CanOptimizeToTyped(const conditions : TTightList; exprClass : TClass) : Boolean;
var
   i : Integer;
   cc : TCaseCondition;
begin
   Result:=True;
   for i:=0 to conditions.Count-1 do begin
      cc:=(conditions.List[i] as TCaseCondition);
      if cc.IsExpr(exprClass) then
         Continue;
      Exit(False);
   end;
end;

// ------------------
// ------------------ TCompareCaseCondition ------------------
// ------------------

// Create
//
constructor TCompareCaseCondition.Create(const aPos : TScriptPos; compareExpr : TTypedExpr);
begin
   inherited Create(aPos);
   FCompareExpr:=compareExpr;
end;

// Destroy
//
destructor TCompareCaseCondition.Destroy;
begin
   FCompareExpr.Free;
   inherited;
end;

// GetSubExpr
//
function TCompareCaseCondition.GetSubExpr(i : Integer) : TExprBase;
begin
   if i=0 then
      Result:=FTrueExpr
   else Result:=FCompareExpr;
end;

// GetSubExprCount
//
function TCompareCaseCondition.GetSubExprCount : Integer;
begin
   Result:=2;
end;

// IsTrue
//
function TCompareCaseCondition.IsTrue(exec : TdwsExecution; const value : Variant) : Boolean;
var
   buf : Variant;
begin
   FCompareExpr.EvalAsVariant(exec, buf);
   Result:=(buf=value);
end;

// StringIsTrue
//
function TCompareCaseCondition.StringIsTrue(exec : TdwsExecution; const value : String) : Boolean;
var
   buf : String;
begin
   FCompareExpr.EvalAsString(exec, buf);
   Result:=(buf=value);
end;

// IntegerIsTrue
//
function TCompareCaseCondition.IntegerIsTrue(const value : Int64) : Boolean;
begin
   Result:=(value=TConstIntExpr(FCompareExpr).Value);
end;

// TypeCheck
//
procedure TCompareCaseCondition.TypeCheck(context : TdwsCompilerContext; typ : TTypeSymbol);
begin
   if FCompareExpr=nil then Exit;
   if (FCompareExpr.Typ=nil) or not (typ.IsCompatible(FCompareExpr.Typ) or FCompareExpr.Typ.IsCompatible(typ)) then
      if not (IsOfTypeNumber(context, FCompareExpr.Typ) and IsOfTypeNumber(context, typ)) then
         context.Msgs.AddCompilerErrorFmt(ScriptPos, CPE_IncompatibleTypes,
                                          [typ.Caption, FCompareExpr.Typ.Caption]);
end;

// IsConstant
//
function TCompareCaseCondition.IsConstant : Boolean;
begin
   Result:=FCompareExpr.IsConstant;
end;

// IsExpr
//
function TCompareCaseCondition.IsExpr(aClass : TClass) : Boolean;
begin
   Result:=FCompareExpr.IsConstant and FCompareExpr.InheritsFrom(aClass);
end;

// ------------------
// ------------------ TCompareConstStringCaseCondition ------------------
// ------------------

// Create
//
constructor TCompareConstStringCaseCondition.Create(const aPos : TScriptPos; const aValue : String);
begin
   inherited Create(aPos);
   FValue := aValue;
end;

// GetSubExpr
//
function TCompareConstStringCaseCondition.GetSubExpr(i : Integer) : TExprBase;
begin
   Result := nil;
end;

// GetSubExprCount
//
function TCompareConstStringCaseCondition.GetSubExprCount : Integer;
begin
   Result := 0;
end;

// IsTrue
//
function TCompareConstStringCaseCondition.IsTrue(exec : TdwsExecution; const value : Variant) : Boolean;
begin
   Result := VariantIsString(value) and (value = FValue);
end;

// StringIsTrue
//
function TCompareConstStringCaseCondition.StringIsTrue(exec : TdwsExecution; const value : String) : Boolean;
begin
   Result := (value = FValue);
end;

// IntegerIsTrue
//
function TCompareConstStringCaseCondition.IntegerIsTrue(const value : Int64) : Boolean;
begin
   Result := False;
end;

// TypeCheck
//
procedure TCompareConstStringCaseCondition.TypeCheck(context : TdwsCompilerContext; typ : TTypeSymbol);
begin
   if not (typ.IsOfType(context.TypString) or typ.IsOfType(context.TypVariant)) then
      context.Msgs.AddCompilerErrorFmt(ScriptPos, CPE_IncompatibleTypes,
                                           [typ.Caption, SYS_STRING]);
end;

// IsConstant
//
function TCompareConstStringCaseCondition.IsConstant : Boolean;
begin
   Result := True;
end;

// IsExpr
//
function TCompareConstStringCaseCondition.IsExpr(aClass : TClass) : Boolean;
begin
   Result := (aClass = TConstStringExpr);
end;

// ------------------
// ------------------ TRangeCaseCondition ------------------
// ------------------

// Create
//
constructor TRangeCaseCondition.Create(const aPos : TScriptPos; fromExpr, toExpr : TTypedExpr);
begin
   inherited Create(aPos);
   FFromExpr:=FromExpr;
   FToExpr:=ToExpr;
end;

// Destroy
//
destructor TRangeCaseCondition.Destroy;
begin
   FFromExpr.Free;
   FToExpr.Free;
   inherited;
end;

// GetSubExpr
//
function TRangeCaseCondition.GetSubExpr(i : Integer) : TExprBase;
begin
   case i of
      0 : Result:=FTrueExpr;
      1 : Result:=FFromExpr;
   else
      Result:=FToExpr;
   end;
end;

// GetSubExprCount
//
function TRangeCaseCondition.GetSubExprCount : Integer;
begin
   Result:=3;
end;

// IsTrue
//
function TRangeCaseCondition.IsTrue(exec : TdwsExecution; const value : Variant) : Boolean;
var
   v : Variant;
begin
   FFromExpr.EvalAsVariant(exec, v);
   if value>=v then begin
      FToExpr.EvalAsVariant(exec, v);
      Result:=(value<=v);
   end else Result:=False;
end;

// StringIsTrue
//
function TRangeCaseCondition.StringIsTrue(exec : TdwsExecution; const value : String) : Boolean;
begin
   Result:=    (value>=TConstStringExpr(FFromExpr).Value)
           and (value<=TConstStringExpr(FToExpr).Value);
end;

// IntegerIsTrue
//
function TRangeCaseCondition.IntegerIsTrue(const value : Int64) : Boolean;
begin
   Result:=    (value>=TConstIntExpr(FFromExpr).Value)
           and (value<=TConstIntExpr(FToExpr).Value);
end;

// TypeCheck
//
procedure TRangeCaseCondition.TypeCheck(context : TdwsCompilerContext; typ : TTypeSymbol);
var
   fromIsNumber : Boolean;
begin
   fromIsNumber:=IsOfTypeNumber(context, FFromExpr.Typ);

   if (FFromExpr.Typ=nil) or (FToExpr.Typ=nil) or not FFromExpr.Typ.IsCompatible(FToExpr.Typ) then begin
      if not (fromIsNumber and IsOfTypeNumber(context, FToExpr.Typ)) then begin
         context.Msgs.AddCompilerErrorFmt(ScriptPos, CPE_RangeIncompatibleTypes,
                                          [FFromExpr.Typ.Caption, FToExpr.Typ.Caption]);
         Exit;
      end;
   end;

   if not typ.IsCompatible(FFromExpr.Typ) then
      if not (fromIsNumber and IsOfTypeNumber(context, typ)) then
         context.Msgs.AddCompilerErrorFmt(ScriptPos, CPE_IncompatibleTypes,
                                          [typ.Caption, FFromExpr.Typ.Caption]);
end;

// IsConstant
//
function TRangeCaseCondition.IsConstant : Boolean;
begin
   Result:=FFromExpr.IsConstant and FToExpr.IsConstant;
end;

// IsExpr
//
function TRangeCaseCondition.IsExpr(aClass : TClass) : Boolean;
begin
   Result:=    FFromExpr.IsConstant and FToExpr.IsConstant
           and FFromExpr.InheritsFrom(aClass) and FToExpr.InheritsFrom(aClass);
end;

// ------------------
// ------------------ TForExpr ------------------
// ------------------

// Create
//
constructor TForExpr.Create(const aPos: TScriptPos);
begin
   inherited Create(aPos);
end;

// Destroy
//
destructor TForExpr.Destroy;
begin
   FDoExpr.Free;
   FFromExpr.Free;
   FToExpr.Free;
   FVarExpr.Free;
   inherited;
end;

// SpecializeProgramExpr
//
function TForExpr.SpecializeProgramExpr(const context : ISpecializationContext) : TProgramExpr;
var
   specialized : TForExpr;
begin
   specialized := TForExprClass(ClassType).Create(ScriptPos);
   specialized.FVarExpr := VarExpr.SpecializeDataExpr(context) as TIntVarExpr;
   specialized.FFromExpr := FromExpr.SpecializeTypedExpr(context);
   specialized.FToExpr := ToExpr.SpecializeTypedExpr(context);
   specialized.FDoExpr := DoExpr.SpecializeProgramExpr(context);
   Result := specialized;
end;

// EnumerateSteppableExprs
//
procedure TForExpr.EnumerateSteppableExprs(const callback : TExprBaseProc);
begin
   callback(DoExpr);
end;

// GetSubExpr
//
function TForExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   case i of
      0 : Result:=FVarExpr;
      1 : Result:=FFromExpr;
      2 : Result:=FToExpr;
   else
      Result:=FDoExpr;
   end;
end;

// GetSubExprCount
//
function TForExpr.GetSubExprCount : Integer;
begin
   Result:=4;
end;

// ------------------
// ------------------ TForStepExpr ------------------
// ------------------

// Destroy
//
destructor TForStepExpr.Destroy;
begin
   FStepExpr.Free;
   inherited;
end;

// EvalStep
//
function TForStepExpr.EvalStep(exec : TdwsExecution) : Int64;
begin
   Result:=FStepExpr.EvalAsInteger(exec);
   if Result<=0 then
      RaiseForLoopStepShouldBeStrictlyPositive(exec, Result);
end;

// RaiseForLoopStepShouldBeStrictlyPositive
//
procedure TForStepExpr.RaiseForLoopStepShouldBeStrictlyPositive(exec : TdwsExecution; index : Int64);
begin
   RaiseScriptError(exec, EScriptError.CreateFmt(RTE_ForLoopStepShouldBeStrictlyPositive, [index]));
end;

// SpecializeProgramExpr
//
function TForStepExpr.SpecializeProgramExpr(const context : ISpecializationContext) : TProgramExpr;
begin
   Result := inherited SpecializeProgramExpr(context);
   (Result as TForStepExpr).FStepExpr := FStepExpr.SpecializeTypedExpr(context);
end;

// GetSubExpr
//
function TForStepExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   if i=4 then
      Result:=FStepExpr
   else Result:=inherited GetSubExpr(i);
end;

// GetSubExprCount
//
function TForStepExpr.GetSubExprCount : Integer;
begin
   Result:=5;
end;

// ------------------
// ------------------ TForUpwardExpr ------------------
// ------------------

procedure TForUpwardExpr.EvalNoResult(exec : TdwsExecution);
var
   dataPtr : Pointer;
   toValue: Int64;
   i : PInt64;
begin
   dataPtr := Pointer(exec.Stack.Data);
   i:=FVarExpr.EvalAsPInteger(exec);
   i^:=FFromExpr.EvalAsInteger(exec);
   toValue:=FToExpr.EvalAsInteger(exec);
   while i^<=toValue do begin
      exec.DoStep(FDoExpr);
      FDoExpr.EvalNoResult(exec);
      if exec.Status<>esrNone then begin
         case exec.Status of
            esrBreak : begin
               exec.Status:=esrNone;
               break;
            end;
            esrContinue :
               exec.Status:=esrNone;
            esrExit : Exit;
         end;
      end;
      if dataPtr <> Pointer(exec.Stack.Data) then begin
         dataPtr := Pointer(exec.Stack.Data);
         i:=FVarExpr.EvalAsPInteger(exec);
      end;
      Inc(i^);
   end;
end;

// ------------------
// ------------------ TForDownwardExpr ------------------
// ------------------

procedure TForDownwardExpr.EvalNoResult(exec : TdwsExecution);
var
   dataPtr : Pointer;
   toValue: Int64;
   i : PInt64;
begin
   dataPtr := Pointer(exec.Stack.Data);
   i:=FVarExpr.EvalAsPInteger(exec);
   i^:=FFromExpr.EvalAsInteger(exec);
   toValue:=FToExpr.EvalAsInteger(exec);
   while i^>=toValue do begin
      exec.DoStep(FDoExpr);
      FDoExpr.EvalNoResult(exec);
      if exec.Status<>esrNone then begin
         case exec.Status of
            esrBreak : begin
               exec.Status:=esrNone;
               break;
            end;
            esrContinue :
               exec.Status:=esrNone;
            esrExit : Exit;
         end;
      end;
      if dataPtr <> Pointer(exec.Stack.Data) then begin
         dataPtr := Pointer(exec.Stack.Data);
         i:=FVarExpr.EvalAsPInteger(exec);
      end;
      Dec(i^);
   end;
end;

// ------------------
// ------------------ TForUpwardStepExpr ------------------
// ------------------

procedure TForUpwardStepExpr.EvalNoResult(exec : TdwsExecution);
var
   dataPtr : Pointer;
   step, toValue: Int64;
   i : PInt64;
begin
   dataPtr := Pointer(exec.Stack.Data);
   i:=FVarExpr.EvalAsPInteger(exec);
   i^:=FFromExpr.EvalAsInteger(exec);
   toValue:=FToExpr.EvalAsInteger(exec);
   step:=EvalStep(exec);
   while i^<=toValue do begin
      exec.DoStep(FDoExpr);
      FDoExpr.EvalNoResult(exec);
      if exec.Status<>esrNone then begin
         case exec.Status of
            esrBreak : begin
               exec.Status:=esrNone;
               break;
            end;
            esrContinue :
               exec.Status:=esrNone;
            esrExit : Exit;
         end;
      end;
      if dataPtr <> Pointer(exec.Stack.Data) then begin
         dataPtr := Pointer(exec.Stack.Data);
         i:=FVarExpr.EvalAsPInteger(exec);
      end;
      try
         {$OVERFLOWCHECKS ON}
         i^:=i^+step;
         {$OVERFLOWCHECKS OFF}
      except
         Break;
      end;
   end;
end;

// ------------------
// ------------------ TForDownwardStepExpr ------------------
// ------------------

procedure TForDownwardStepExpr.EvalNoResult(exec : TdwsExecution);
var
   dataPtr : Pointer;
   step, toValue: Int64;
   i : PInt64;
begin
   dataPtr := Pointer(exec.Stack.Data);
   i:=FVarExpr.EvalAsPInteger(exec);
   i^:=FFromExpr.EvalAsInteger(exec);
   toValue:=FToExpr.EvalAsInteger(exec);
   step:=EvalStep(exec);
   while i^>=toValue do begin
      exec.DoStep(FDoExpr);
      FDoExpr.EvalNoResult(exec);
      if exec.Status<>esrNone then begin
         case exec.Status of
            esrBreak : begin
               exec.Status:=esrNone;
               break;
            end;
            esrContinue :
               exec.Status:=esrNone;
            esrExit : Exit;
         end;
      end;
      if dataPtr <> Pointer(exec.Stack.Data) then begin
         dataPtr := Pointer(exec.Stack.Data);
         i:=FVarExpr.EvalAsPInteger(exec);
      end;
      try
         {$OVERFLOWCHECKS ON}
         i^:=i^-step;
         {$OVERFLOWCHECKS OFF}
      except
         Break;
      end;
   end;
end;

// ------------------
// ------------------ TLoopExpr ------------------
// ------------------

// Destroy
//
destructor TLoopExpr.Destroy;
begin
   FCondExpr.Free;
   FLoopExpr.Free;
   inherited;
end;

// EvalNoResult
//
procedure TLoopExpr.EvalNoResult(exec : TdwsExecution);
begin
   repeat
      exec.DoStep(FLoopExpr);
      FLoopExpr.EvalNoResult(exec);
      if exec.Status<>esrNone then begin
         case exec.Status of
            esrBreak : begin
               exec.Status:=esrNone;
               Break;
            end;
            esrContinue :
               exec.Status:=esrNone;
            esrExit : Exit;
         end;
      end;
   until False;
end;

// SpecializeProgramExpr
//
function TLoopExpr.SpecializeProgramExpr(const context : ISpecializationContext) : TProgramExpr;
var
   specialized : TLoopExpr;
begin
   specialized := TLoopExprClass(ClassType).Create(ScriptPos);
   specialized.CondExpr := CondExpr.SpecializeBooleanExpr(context);
   specialized.LoopExpr := LoopExpr.SpecializeProgramExpr(context);
   Result := specialized;
end;

// EnumerateSteppableExprs
//
procedure TLoopExpr.EnumerateSteppableExprs(const callback : TExprBaseProc);
begin
   callback(LoopExpr);
end;

// GetSubExpr
//
function TLoopExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   if i=0 then
      Result:=FCondExpr
   else Result:=FLoopExpr;
end;

// GetSubExprCount
//
function TLoopExpr.GetSubExprCount : Integer;
begin
   Result:=2;
end;

{ TWhileExpr }

procedure TWhileExpr.EvalNoResult(exec : TdwsExecution);
begin
   while FCondExpr.EvalAsBoolean(exec) do begin
      exec.DoStep(FLoopExpr);
      FLoopExpr.EvalNoResult(exec);
      if exec.Status<>esrNone then begin
         case exec.Status of
            esrBreak : begin
               exec.Status:=esrNone;
               Break;
            end;
            esrContinue :
               exec.Status:=esrNone;
            esrExit : Exit;
         end;
      end;
   end;
end;

// Optimize
//
function TWhileExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   Result:=Self;
   if FCondExpr.IsConstant then begin
      if not FCondExpr.EvalAsBoolean(context.Execution) then begin
         Result:=TNullExpr.Create(FScriptPos);
      end else begin
         Result:=TLoopExpr.Create(FScriptPos);
         TLoopExpr(Result).FLoopExpr:=FLoopExpr;
         FLoopExpr:=nil;
      end;
      Orphan(context);
   end;
end;

{ TRepeatExpr }

procedure TRepeatExpr.EvalNoResult(exec : TdwsExecution);
begin
   repeat
      exec.DoStep(FLoopExpr);
      FLoopExpr.EvalNoResult(exec);
      if exec.Status<>esrNone then begin
         case exec.Status of
            esrBreak : begin
               exec.Status:=esrNone;
               Break;
            end;
            esrContinue :
               exec.Status:=esrNone;
            esrExit : Exit;
         end;
      end;
      exec.DoStep(Self);
   until FCondExpr.EvalAsBoolean(exec);
end;

// Optimize
//
function TRepeatExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   Result:=Self;
   if FCondExpr.IsConstant and not FCondExpr.EvalAsBoolean(context.Execution) then begin
      Result:=TLoopExpr.Create(FScriptPos);
      TLoopExpr(Result).FLoopExpr:=FLoopExpr;
      FLoopExpr:=nil;
      Orphan(context);
   end;
end;

// ------------------
// ------------------ TFlowControlExpr ------------------
// ------------------

// InterruptsFlow
//
function TFlowControlExpr.InterruptsFlow : Boolean;
begin
   Result:=True;
end;

// ------------------
// ------------------ TBreakExpr ------------------
// ------------------

// EvalNoResult
//
procedure TBreakExpr.EvalNoResult(exec : TdwsExecution);
begin
   exec.Status:=esrBreak;
end;

// ------------------
// ------------------ TBreakExpr ------------------
// ------------------

// EvalNoResult
//
procedure TExitExpr.EvalNoResult(exec : TdwsExecution);
begin
   exec.Status:=esrExit;
end;

// ------------------
// ------------------ TExitValueExpr ------------------
// ------------------

// Create
//
constructor TExitValueExpr.Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos; assignExpr : TAssignExpr);
begin
   inherited Create(aScriptPos);
   FAssignExpr:=assignExpr;
end;

// Destroy
//
destructor TExitValueExpr.Destroy;
begin
   FAssignExpr.Free;
   inherited;
end;

// EvalNoResult
//
procedure TExitValueExpr.EvalNoResult(exec : TdwsExecution);
begin
   FAssignExpr.EvalNoResult(exec);
   exec.Status:=esrExit;
end;

// GetSubExpr
//
function TExitValueExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   Result:=FAssignExpr;
end;

// GetSubExprCount
//
function TExitValueExpr.GetSubExprCount : Integer;
begin
   Result:=1;
end;

// ------------------
// ------------------ TContinueExpr ------------------
// ------------------

procedure TContinueExpr.EvalNoResult(exec : TdwsExecution);
begin
   exec.Status:=esrContinue;
end;

// ------------------
// ------------------ TExceptionExpr ------------------
// ------------------

// Create
//
constructor TExceptionExpr.Create(tryExpr : TProgramExpr);
begin
   inherited Create(tryExpr.ScriptPos);
   FTryExpr:=tryExpr;
end;

destructor TExceptionExpr.Destroy;
begin
  FTryExpr.Free;
  FHandlerExpr.Free;
  inherited;
end;

// EnumerateSteppableExprs
//
procedure TExceptionExpr.EnumerateSteppableExprs(const callback : TExprBaseProc);
begin
   callback(TryExpr);
   callback(HandlerExpr);
end;

// GetSubExpr
//
function TExceptionExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   if i=0 then
      Result:=FTryExpr
   else Result:=FHandlerExpr;
end;

// GetSubExprCount
//
function TExceptionExpr.GetSubExprCount : Integer;
begin
   Result:=2;
end;

{ TExceptExpr }

destructor TExceptExpr.Destroy;
begin
  inherited;
  FDoExprs.Clean;
  FElseExpr.Free;
end;

// EvalNoResult
//
procedure TExceptExpr.EvalNoResult(exec : TdwsExecution);
var
   x : Integer;
   exceptObj : IScriptObj;
   objSym : TTypeSymbol;
   doExpr : TExceptDoExpr;
   isCaught : Boolean;
   isReraise : Boolean;
   systemExceptObject : TObject;
   exceptVar : TDataSymbol;
begin
   try
      exec.DoStep(FTryExpr);
      FTryExpr.EvalNoResult(exec);
   except
      {$ifdef FPC}
      systemExceptObject:=SysUtils.ExceptObject;
      {$else}
      systemExceptObject:=System.ExceptObject;
      {$endif}
      if    (systemExceptObject.ClassType=EScriptStopped)
         or not (systemExceptObject is Exception) then raise;

      exec.EnterExceptionBlock(exceptObj);
      try

         isReraise := False;

         // script exceptions
         if FDoExprs.Count > 0 then begin

            isCaught := False;

            if exceptObj<>nil then begin

               objSym := exceptObj.ClassSym;

               for x := 0 to FDoExprs.Count - 1 do begin
                  // Find a "on x: Class do ..." statement matching to this exception class
                  doExpr := TExceptDoExpr(FDoExprs.List[x]);
                  exceptVar:=doExpr.ExceptionVar;
                  if exceptVar.Typ.IsCompatible(objSym) then begin
                     exec.Stack.Data[exec.Stack.BasePointer+exceptVar.StackAddr] := exceptObj;
                     try
                        exec.DoStep(doExpr);
                        doExpr.EvalNoResult(exec);
                     except
                        on E : EReraise do isReraise := True;
                     end;
                     if isReraise then break;
                     VarClearSafe(exec.Stack.Data[exec.Stack.BasePointer+exceptVar.StackAddr]);
                     isCaught := True;
                     Break;
                  end;
               end;

            end else isReraise:=(FDoExprs.Count>0);

            if (not isReraise) and (not isCaught) then begin
               if Assigned(FElseExpr) then begin
                  try
                     exec.DoStep(FElseExpr);
                     FElseExpr.EvalNoResult(exec);
                  except
                     on E : EReraise do isReraise := True;
                  end;
               end else isReraise:=True;
            end;

         end else begin

            try
               exec.DoStep(FHandlerExpr);
               FHandlerExpr.EvalNoResult(exec);
            except
               on E : EReraise do isReraise := True;
            end;

         end;

      finally
         exec.LeaveExceptionBlock;
      end;

      if isReraise then raise;
   end;
   exec.ClearScriptError;
end;

// AddDoExpr
//
procedure TExceptExpr.AddDoExpr(expr : TExceptDoExpr);
begin
   FDoExprs.Add(expr);
end;

// DoExprCount
//
function TExceptExpr.DoExprCount : Integer;
begin
   Result:=FDoExprs.Count;
end;

// EnumerateSteppableExprs
//
procedure TExceptExpr.EnumerateSteppableExprs(const callback : TExprBaseProc);
var
   i : Integer;
begin
   inherited EnumerateSteppableExprs(callback);
   for i := 0 to DoExprCount-1 do
      callback(DoExpr[i]);
   callback(ElseExpr);
end;

// GetSubExpr
//
function TExceptExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   if i<2 then
      Result:=inherited GetSubExpr(i)
   else if i<2+FDoExprs.Count then
      Result:=TExprBase(FDoExprs.List[i-2])
   else Result:=FElseExpr;
end;

// GetSubExprCount
//
function TExceptExpr.GetSubExprCount : Integer;
begin
   Result:=3+FDoExprs.Count;
end;

// GetDoExpr
//
function TExceptExpr.GetDoExpr(i : Integer) : TExceptDoExpr;
begin
   Result:=TExceptDoExpr(FDoExprs.List[i]);
end;

// ------------------
// ------------------ TFinallyExpr ------------------
// ------------------

// EvalNoResult
//
procedure TFinallyExpr.EvalNoResult(exec : TdwsExecution);
var
   oldStatus : TExecutionStatusResult;
   systemExceptObj : TObject;
   exceptObj : IScriptObj;
begin
   try
      exec.DoStep(FTryExpr);
      FTryExpr.EvalNoResult(exec);
   finally
      oldStatus:=exec.Status;
      try
         exec.Status:=esrNone;
         {$ifdef FPC}
         systemExceptObj:=SysUtils.ExceptObject;
         {$else}
         systemExceptObj:=System.ExceptObject;
         {$endif}
         if (systemExceptObj=nil) or (systemExceptObj.ClassType<>EScriptStopped) then begin
            if systemExceptObj is Exception then begin
               exec.EnterExceptionBlock(exceptObj);
               try
                  exec.DoStep(FHandlerExpr);
                  FHandlerExpr.EvalNoResult(exec);
               finally
                  exec.LeaveExceptionBlock;
               end;
            end else begin
               exec.DoStep(FHandlerExpr);
               FHandlerExpr.EvalNoResult(exec);
            end;
         end;
      finally
         exec.Status:=oldStatus;
      end;
   end;
end;

// ------------------
// ------------------ TRaiseExpr ------------------
// ------------------

// Create
//
constructor TRaiseExpr.Create(context : TdwsCompilerContext; const scriptPos : TScriptPos; ExceptionExpr: TTypedExpr);
begin
   inherited Create(scriptPos);
   FExceptionExpr:=ExceptionExpr;
end;

// Destroy
//
destructor TRaiseExpr.Destroy;
begin
   FExceptionExpr.Free;
   inherited;
end;

// EvalNoResult
//
procedure TRaiseExpr.EvalNoResult(exec : TdwsExecution);
var
   exceptObj : IScriptObj;
   exceptMessage : String;
   e : EScriptException;
begin
   FExceptionExpr.EvalAsScriptObj(exec, exceptObj);
   CheckScriptObject(exec, exceptObj);
   exceptObj.EvalAsString(0, exceptMessage);
   if exceptObj.ClassSym.Name<>SYS_EDELPHI then begin
      if exceptMessage<>'' then
         exceptMessage:=Format(RTE_UserDefinedException_Msg, [exceptMessage])
      else exceptMessage:=RTE_UserDefinedException;
   end;
   e:=EScriptException.Create(exceptMessage, exceptObj, FScriptPos);
   e.ScriptCallStack:=exec.GetCallStack;
   exec.SetScriptError(Self);
   if exec.IsDebugging then
      exec.DebuggerNotifyException(exceptObj);
   raise e;
end;

// InterruptsFlow
//
function TRaiseExpr.InterruptsFlow : Boolean;
begin
   Result:=True;
end;

// GetSubExpr
//
function TRaiseExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   Result:=FExceptionExpr;
end;

// GetSubExprCount
//
function TRaiseExpr.GetSubExprCount : Integer;
begin
   Result:=1;
end;

// ------------------
// ------------------ TReraiseExpr ------------------
// ------------------

// EvalNoResult
//
procedure TReraiseExpr.EvalNoResult(exec : TdwsExecution);
begin
   raise EReraise.Create('');
end;

// ------------------
// ------------------ TExceptDoExpr ------------------
// ------------------

// Create
//
constructor TExceptDoExpr.Create(context : TdwsCompilerContext; const aPos: TScriptPos);
begin
   inherited Create(aPos);
   FExceptionTable:=TSymbolTable.Create(context.Table, context.Table.AddrGenerator);
end;

// Destroy
//
destructor TExceptDoExpr.Destroy;
begin
   FDoBlockExpr.Free;
   FExceptionTable.Free;
   inherited;
end;

// EvalNoResult
//
procedure TExceptDoExpr.EvalNoResult(exec : TdwsExecution);
begin
   exec.DoStep(DoBlockExpr);
   DoBlockExpr.EvalNoResult(exec);
end;

// ReferencesVariable
//
function TExceptDoExpr.ReferencesVariable(varSymbol : TDataSymbol) : Boolean;
begin
   Result:=   FExceptionTable.HasSymbol(varSymbol)
           or inherited ReferencesVariable(varSymbol);
end;

// ExceptionVar
//
function TExceptDoExpr.ExceptionVar : TDataSymbol;
begin
   Result:=FExceptionTable.Symbols[0] as TDataSymbol;
end;

// GetSubExpr
//
function TExceptDoExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   Result:=FDoBlockExpr;
end;

// GetSubExprCount
//
function TExceptDoExpr.GetSubExprCount : Integer;
begin
   Result:=1;
end;

// ------------------
// ------------------ TStringArraySetExpr ------------------
// ------------------

// Create
//
constructor TStringArraySetExpr.Create(context : TdwsCompilerContext; const aScriptPos: TScriptPos;
                     StringExpr : TDataExpr; IndexExpr, ValueExpr: TTypedExpr);
begin
   inherited Create(aScriptPos);
   FStringExpr:=StringExpr;
   FIndexExpr:=IndexExpr;
   FValueExpr:=ValueExpr;
end;

// Destroy
//
destructor TStringArraySetExpr.Destroy;
begin
   FStringExpr.Free;
   FIndexExpr.Free;
   FValueExpr.Free;
   inherited;
end;

// EvalNoResult
//
procedure TStringArraySetExpr.EvalNoResult(exec : TdwsExecution);
var
   i : Integer;
   s, buf : String;
begin
   FStringExpr.EvalAsString(exec, s);
   i:=FIndexExpr.EvalAsInteger(exec);
   if i>Length(s) then
      RaiseUpperExceeded(exec, i)
   else if i<1 then
      RaiseLowerExceeded(exec, i);
   FValueExpr.EvalAsString(exec, buf);
   if Length(buf)<>1 then
      RaiseScriptError(exec, EScriptError.CreateFmt(RTE_InvalidInputDataSize, [Length(buf), 1]));
   s[i]:=buf[1];
   FStringExpr.AssignValue(exec, s);
end;

// GetSubExpr
//
function TStringArraySetExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   case i of
      0 : Result:=FStringExpr;
      1 : Result:=FIndexExpr;
   else
      Result:=FValueExpr;
   end;
end;

// GetSubExprCount
//
function TStringArraySetExpr.GetSubExprCount : Integer;
begin
   Result:=3;
end;

// ------------------
// ------------------ TVarStringArraySetExpr ------------------
// ------------------

// EvalNoResult
//
procedure TVarStringArraySetExpr.EvalNoResult(exec : TdwsExecution);
var
   i : Integer;
   c : WideChar;
begin
   i:=FIndexExpr.EvalAsInteger(exec);
   if i<1 then
      RaiseLowerExceeded(exec, i);
   c:=EvalValueAsWideChar(exec);
   if not TStrVarExpr(FStringExpr).SetChar(exec, i, c) then
      RaiseUpperExceeded(exec, i);
end;

// EvalValueAsWideChar
//
function TVarStringArraySetExpr.EvalValueAsWideChar(exec : TdwsExecution) : WideChar;
var
   buf : String;
begin
   FValueExpr.EvalAsString(exec, buf);
   if Length(buf)<>1 then
      RaiseScriptError(exec, EScriptError.CreateFmt(RTE_InvalidInputDataSize, [Length(buf), 1]));
   Result:=buf[1];
end;

// ------------------
// ------------------ TVarStringArraySetChrExpr ------------------
// ------------------

// EvalValueAsWideChar
//
function TVarStringArraySetChrExpr.EvalValueAsWideChar(exec : TdwsExecution) : WideChar;
var
   i : Integer;
begin
   i:=FValueExpr.EvalAsInteger(exec);
   if i>$FFFF then
      RaiseScriptError(exec, EScriptError.CreateFmt(RTE_InvalidInputDataSize, [2, 1]));
   Result:=WideChar(i);
end;

// ------------------
// ------------------ TSpecialUnaryBoolExpr ------------------
// ------------------

// GetIsConstant
//
function TSpecialUnaryBoolExpr.GetIsConstant : Boolean;
begin
   Result:=False;
end;

// ------------------
// ------------------ TConditionalDefinedExpr ------------------
// ------------------

// EvalAsBoolean
//
function TConditionalDefinedExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   name : String;
begin
   Expr.EvalAsString(exec, name);
   Result:=((exec as TdwsProgramExecution).Prog.ConditionalDefines.Value.IndexOf(name)>=0);
end;

// ------------------
// ------------------ TDefinedExpr ------------------
// ------------------

// EvalAsBoolean
//
function TDefinedExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   v : Variant;
begin
   Expr.EvalAsVariant(exec, v);
   Result := (VariantType(v) <> varEmpty);
end;

// ------------------
// ------------------ TDeclaredExpr ------------------
// ------------------

// EvalAsBoolean
//
function TDeclaredExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   name : String;
begin
   Expr.EvalAsString(exec, name);
   Result:=(FindSymbol((exec as TdwsProgramExecution).Prog.Table, name)<>nil);
end;

// FindSymbol
//
class function TDeclaredExpr.FindSymbol(symbolTable : TSymbolTable; const name : String) : TSymbol;
var
   p, i : Integer;
   identifier : String;
   helpers : THelperSymbols;
   sym : TSymbol;
begin
   p:=Pos('.', name);
   if p<=0 then
      Result:=symbolTable.FindSymbol(name, cvMagic)
   else begin
      Result:=symbolTable.FindSymbol(Copy(name, 1, p-1), cvMagic);
      if Result=nil then Exit;
      identifier:=StrDeleteLeft(name, p);
      if Result.ClassType=TUnitSymbol then
         Result:=FindSymbol(TUnitSymbol(Result).Table, identifier)
      else begin
         sym:=Result;
         if Result.InheritsFrom(TCompositeTypeSymbol) then begin
            Result:=FindSymbol(TCompositeTypeSymbol(Result).Members, identifier);
            if Result<>nil then Exit;
         end;
         if sym is TTypeSymbol then begin
            helpers:=THelperSymbols.Create;
            try
               symbolTable.EnumerateHelpers(TTypeSymbol(sym), helpers.AddHelper);
               for i:=0 to helpers.Count-1 do begin
                  Result:=helpers[i].Members.FindSymbol(identifier, cvMagic);
                  if Result<>nil then Exit;
               end;
            finally
               helpers.Free;
            end;
         end;
         Result:=nil;
      end;
   end;
end;

// ------------------
// ------------------ TDebugBreakExpr ------------------
// ------------------

// EvalNoResult
//
procedure TDebugBreakExpr.EvalNoResult(exec : TdwsExecution);
begin
   // nothing
end;

// ------------------
// ------------------ TArrayPseudoMethodExpr ------------------
// ------------------

// Create
//
constructor TArrayPseudoMethodExpr.Create(const scriptPos: TScriptPos; aBase : TTypedExpr);
begin
   inherited Create(scriptPos);
   FBaseExpr:=aBase;
end;

// Destroy
//
destructor TArrayPseudoMethodExpr.Destroy;
begin
   inherited;
   FBaseExpr.Free;
end;

// GetSubExpr
//
function TArrayPseudoMethodExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   Result:=FBaseExpr;
end;

// GetSubExprCount
//
function TArrayPseudoMethodExpr.GetSubExprCount : Integer;
begin
   Result:=1;
end;

// ------------------
// ------------------ TArraySetLengthExpr ------------------
// ------------------

// Create
//
constructor TArraySetLengthExpr.Create(const scriptPos: TScriptPos;
                                       aBase, aLength : TTypedExpr);
begin
   inherited Create(scriptPos, aBase);
   FLengthExpr:=aLength;
end;

// Destroy
//
destructor TArraySetLengthExpr.Destroy;
begin
   inherited;
   FLengthExpr.Free;
end;

// GetSubExpr
//
function TArraySetLengthExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   if i=0 then
      Result:=FBaseExpr
   else Result:=FLengthExpr;
end;

// GetSubExprCount
//
function TArraySetLengthExpr.GetSubExprCount : Integer;
begin
   Result:=2;
end;

// EvalNoResult
//
procedure TArraySetLengthExpr.EvalNoResult(exec : TdwsExecution);
var
   dyn : IScriptDynArray;
   n : Integer;
begin
   BaseExpr.EvalAsScriptDynArray(exec, dyn);
   n:=LengthExpr.EvalAsInteger(exec);
   if n<0 then
      RaiseScriptError(exec, EScriptOutOfBounds.CreatePosFmt(FScriptPos, RTE_ArrayLengthIncorrect, [n]));
   dyn.ArrayLength:=n;
end;

// ------------------
// ------------------ TArraySwapExpr ------------------
// ------------------

// Create
//
constructor TArraySwapExpr.Create(context : TdwsCompilerContext; const scriptPos: TScriptPos;
                                  aBase, aIndex1, aIndex2 : TTypedExpr);
begin
   inherited Create(context, scriptPos, aBase);
   FIndex1Expr:=aIndex1;
   FIndex2Expr:=aIndex2;
end;

// Destroy
//
destructor TArraySwapExpr.Destroy;
begin
   inherited;
   FIndex1Expr.Free;
   FIndex2Expr.Free;
end;

// EvalAsScriptDynArray
//
procedure TArraySwapExpr.EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray);
var
   dyn : TScriptDynamicArray;
   i1, i2 : Integer;
begin
   BaseExpr.EvalAsScriptDynArray(exec, result);
   dyn:=TScriptDynamicArray(result.GetSelf);
   i1:=Index1Expr.EvalAsInteger(exec);
   i2:=Index2Expr.EvalAsInteger(exec);
   BoundsCheck(exec, dyn.ArrayLength, i1);
   BoundsCheck(exec, dyn.ArrayLength, i2);
   dyn.Swap(i1, i2);
end;

// GetSubExpr
//
function TArraySwapExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   case i of
      0 : Result:=BaseExpr;
      1 : Result:=Index1Expr;
   else
      Result:=Index2Expr;
   end;
end;

// GetSubExprCount
//
function TArraySwapExpr.GetSubExprCount : Integer;
begin
   Result:=3;
end;

// ------------------
// ------------------ TArraySortComparer ------------------
// ------------------

type
   TArraySortComparer = class
      FExec : TdwsExecution;
      FDyn : TScriptDynamicArray;
      FFunc : TFuncPtrExpr;
      FFuncPointer : IFuncPointer;
      FLeftAddr, FRightAddr : Integer;
      FData : TData;
      constructor Create(exec : TdwsExecution; dyn : TScriptDynamicArray; compareFunc : TFuncPtrExpr);
      function CompareData(index1, index2 : Integer) : Integer;
      function CompareValue(index1, index2 : Integer) : Integer;
   end;

// Create
//
constructor TArraySortComparer.Create(exec : TdwsExecution; dyn : TScriptDynamicArray;
                                      compareFunc : TFuncPtrExpr);
begin
   FExec:=exec;
   FDyn:=dyn;
   FData:=dyn.AsPData^;
   FLeftAddr:=exec.Stack.BasePointer+(compareFunc.Args[0] as TVarExpr).StackAddr;
   FRightAddr:=exec.Stack.BasePointer+(compareFunc.Args[1] as TVarExpr).StackAddr;
   FFunc:=compareFunc;
   compareFunc.EvalAsFuncPointer(exec, FFuncPointer);
end;

// CompareData
//
function TArraySortComparer.CompareData(index1, index2 : Integer) : Integer;
begin
   DWSCopyData(FData, index1*FDyn.ElementSize, FExec.Stack.Data, FLeftAddr, FDyn.ElementSize);
   DWSCopyData(FData, index2*FDyn.ElementSize, FExec.Stack.Data, FRightAddr, FDyn.ElementSize);
   Result:=FFuncPointer.EvalAsInteger(FExec, FFunc);
end;

// CompareValue
//
function TArraySortComparer.CompareValue(index1, index2 : Integer) : Integer;
begin
   VarCopySafe(FExec.Stack.Data[FLeftAddr], FData[index1]);
   VarCopySafe(FExec.Stack.Data[FRightAddr], FData[index2]);
   Result:=FFuncPointer.EvalAsInteger(FExec, FFunc);
end;

// ------------------
// ------------------ TArraySortExpr ------------------
// ------------------

// Create
//
constructor TArraySortExpr.Create(context : TdwsCompilerContext; const scriptPos: TScriptPos;
                                  aBase : TTypedExpr; aCompare : TFuncPtrExpr);
var
   elemTyp : TTypeSymbol;
begin
   inherited Create(context, scriptPos, aBase);
   FCompareExpr:=aCompare;
   if aCompare<>nil then begin
      elemTyp:=aCompare.FuncSym.Params[0].Typ;
      FLeft:=TScriptDataSymbol.Create('', elemTyp);
      context.Table.AddSymbol(FLeft);
      FRight:=TScriptDataSymbol.Create('', elemTyp);
      context.Table.AddSymbol(FRight);
      FCompareExpr.AddArg(TVarExpr.CreateTyped(context, FLeft));
      FCompareExpr.AddArg(TVarExpr.CreateTyped(context, FRight));
   end;
end;

// Destroy
//
destructor TArraySortExpr.Destroy;
begin
   FCompareExpr.Free;
   inherited;
end;

// EvalAsScriptDynArray
//
procedure TArraySortExpr.EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray);
var
   dyn : TScriptDynamicValueArray;
   qs : TQuickSort;
   comparer : TArraySortComparer;
begin
   BaseExpr.EvalAsScriptDynArray(exec, result);
   dyn:=TScriptDynamicValueArray(result.GetSelf);
   comparer:=TArraySortComparer.Create(exec, dyn, CompareExpr);
   try
      if dyn.ElementSize>1 then
         qs.CompareMethod:=comparer.CompareData
      else qs.CompareMethod:=comparer.CompareValue;
      qs.SwapMethod:=dyn.Swap;
      qs.Sort(0, dyn.ArrayLength-1);
   finally
      comparer.Free;
   end;
end;


// GetSubExpr
//
function TArraySortExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   if i=0 then
      Result:=BaseExpr
   else Result:=CompareExpr;
end;

// GetSubExprCount
//
function TArraySortExpr.GetSubExprCount : Integer;
begin
   Result:=2;
end;

// ------------------
// ------------------ TArraySortNaturalExpr ------------------
// ------------------

// EvalAsScriptDynArray
//
procedure TArraySortNaturalExpr.EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray);
var
   dyn : TScriptDynamicValueArray;
   qs : TQuickSort;
begin
   BaseExpr.EvalAsScriptDynArray(exec, result);
   dyn:=TScriptDynamicValueArray(result.GetSelf);
   SetCompareMethod(qs, dyn);
   qs.SwapMethod:=dyn.Swap;
   qs.Sort(0, dyn.ArrayLength-1);
end;

// SetCompareMethod
//
procedure TArraySortNaturalExpr.SetCompareMethod(var qs : TQuickSort; dyn : TScriptDynamicValueArray);
begin
   raise Exception.CreateFmt('%s does not yet supports %s', [ClassName, dyn.ClassName]);
end;

// ------------------
// ------------------ TArraySortNaturalStringExpr ------------------
// ------------------

// SetCompareMethod
//
procedure TArraySortNaturalStringExpr.SetCompareMethod(var qs : TQuickSort; dyn : TScriptDynamicValueArray);
begin
   qs.CompareMethod:=dyn.CompareString;
end;

// ------------------
// ------------------ TArraySortNaturalIntegerExpr ------------------
// ------------------

// SetCompareMethod
//
procedure TArraySortNaturalIntegerExpr.SetCompareMethod(var qs : TQuickSort; dyn : TScriptDynamicValueArray);
begin
   qs.CompareMethod:=dyn.CompareInteger;
end;

// ------------------
// ------------------ TArraySortNaturalFloatExpr ------------------
// ------------------

// SetCompareMethod
//
procedure TArraySortNaturalFloatExpr.SetCompareMethod(var qs : TQuickSort; dyn : TScriptDynamicValueArray);
begin
   qs.CompareMethod:=dyn.CompareFloat;
end;

// ------------------
// ------------------ TArrayMapExpr ------------------
// ------------------

// Create
//
constructor TArrayMapExpr.Create(context : TdwsCompilerContext; const scriptPos: TScriptPos;
                                 aBase : TTypedExpr; aMapFunc : TFuncPtrExpr);
var
   elemTyp : TTypeSymbol;
   arrayTyp : TDynamicArraySymbol;
begin
   inherited Create(context, scriptPos, aBase);
   FMapFuncExpr:=aMapFunc;
   if aMapFunc<>nil then
      elemTyp:=aMapFunc.Typ
   else elemTyp:=nil;
   if elemTyp=nil then
      elemTyp:=context.TypVariant;
   arrayTyp:=TDynamicArraySymbol.Create('', elemTyp, context.TypInteger);
   context.Table.AddSymbol(arrayTyp);
   Typ:=arrayTyp;

   if aMapFunc<>nil then begin
      elemTyp:=aMapFunc.FuncSym.Params[0].Typ;
      FItem:=TScriptDataSymbol.Create('', elemTyp);
      context.Table.AddSymbol(FItem);
      FMapFuncExpr.AddArg(TVarExpr.CreateTyped(context, FItem));
      FMapFuncExpr.InitializeResultAddr(context.Prog as TdwsProgram);
   end;
end;

// Destroy
//
destructor TArrayMapExpr.Destroy;
begin
   inherited;
   FMapFuncExpr.Free;
end;

// EvalAsVariant
//
procedure TArrayMapExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   dyn : IScriptDynArray;
begin
   EvalAsScriptDynArray(exec, dyn);
   VarCopySafe(Result, dyn);
end;

// EvalAsScriptDynArray
//
procedure TArrayMapExpr.EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray);
var
   newArray : TScriptDynamicArray;
   base : IScriptDynArray;
   dyn : TScriptDynamicValueArray;
   i, itemAddr : Integer;
   funcPointer : IFuncPointer;
   newPData, oldPData : PData;
   dc : IDataContext;
begin
   BaseExpr.EvalAsScriptDynArray(exec, base);
   MapFuncExpr.EvalAsFuncPointer(exec, funcPointer);

   dyn:=TScriptDynamicValueArray(base.GetSelf);
   oldPData:=dyn.AsPData;

   newArray:=TScriptDynamicArray.CreateNew(Typ.Typ);
   result:=IScriptDynArray(newArray);
   newArray.ArrayLength:=dyn.ArrayLength;
   newPData:=newArray.AsPData;

   itemAddr:=exec.Stack.BasePointer+FItem.StackAddr;
   for i:=0 to dyn.ArrayLength-1 do begin
      if dyn.ElementSize = 1 then
         exec.Stack.WriteValue(itemAddr, oldPData^[i])
      else dyn.CopyData(i*dyn.ElementSize, exec.Stack.Data, itemAddr, dyn.ElementSize);
      if newArray.ElementSize = 1 then
         funcPointer.EvalAsVariant(exec, MapFuncExpr, newPData^[i])
      else begin
         dc:=funcPointer.EvalDataPtr(exec,  MapFuncExpr, MapFuncExpr.ResultAddr);
         dc.CopyData(newPData^, i*newArray.ElementSize, newArray.ElementSize);
      end;
   end;
end;

// BaseAsCallback
//
procedure TArrayMapExpr.BaseAsCallback(exec : TdwsExecution; const initial, callback : TArrayDataEnumeratorCallback);
var
   base : IScriptDynArray;
   dyn : TScriptDynamicValueArray;
   destPVariant : PVariant;
   i : Integer;
begin
   if BaseExpr is TArrayMapExpr then begin

      TArrayMapExpr(BaseExpr).EvalAsCallback(exec, initial, callback);

   end else begin

      BaseExpr.EvalAsScriptDynArray(exec, base);
      dyn := TScriptDynamicValueArray(base.GetSelf);
      destPVariant := initial(dyn.ArrayLength);
      if dyn.ElementSize = 1 then begin
         i := 0;
         while i < dyn.ArrayLength do begin
            VarCopySafe(destPVariant^, dyn.AsPVariant(i)^);
            destPVariant := callback(i);
            Inc(i);
         end;
      end else begin
         i := 0;
         while i < dyn.ArrayLength do begin
            dyn.CopyData(i*dyn.ElementSize, destPVariant^, 0, dyn.ElementSize);
            destPVariant := callback(i);
            Inc(i);
         end;
      end;

   end;
end;

// EvalAsCallback
//
procedure TArrayMapExpr.EvalAsCallback(exec : TdwsExecution; const initial, callback : TArrayDataEnumeratorCallback);
var
   itemAddr, destSize : Integer;
   itemPtr : PVariant;
   funcPointer : IFuncPointer;
   destPVariant : PVariant;
   loopCallback : TArrayDataEnumeratorCallback;

{$IFDEF FPC}
   function A(n : Integer) : PVariant;
   begin
      funcPointer.EvalAsVariant(exec, MapFuncExpr, destPVariant^);
      destPVariant := callback(n);
      Result := itemPtr;
   end;

   function B(n : Integer) : PVariant;
   var
      dc : IDataContext;
   begin
      dc := funcPointer.EvalDataPtr(exec,  MapFuncExpr, MapFuncExpr.ResultAddr);
      dc.CopyData(destPVariant^, 0, destSize);
      destPVariant := callback(n);
      Result := itemPtr;
   end;

   function C(n : Integer) : PVariant;
   begin
      destPVariant := initial(n);
      Result := itemPtr;
   end;
{$ENDIF}

begin
   MapFuncExpr.EvalAsFuncPointer(exec, funcPointer);

   itemAddr := exec.Stack.BasePointer + FItem.StackAddr;
   itemPtr := @exec.Stack.Data[itemAddr];

   destSize := Typ.Typ.Size;
{$IFDEF FPC}
   if destSize = 1 then begin
      loopCallback := @A;
   end else begin
      loopCallback := @B;
   end;
   BaseAsCallback(exec, @C, loopCallback);
{$ELSE}
   if destSize = 1 then begin
      loopCallback := function(n : Integer) : PVariant
      begin
         funcPointer.EvalAsVariant(exec, MapFuncExpr, destPVariant^);
         destPVariant := callback(n);
         Result := itemPtr;
      end;
   end else begin
      loopCallback := function(n : Integer) : PVariant
      var
         dc : IDataContext;
      begin
         dc := funcPointer.EvalDataPtr(exec,  MapFuncExpr, MapFuncExpr.ResultAddr);
         dc.CopyData(destPVariant^, 0, destSize);
         destPVariant := callback(n);
         Result := itemPtr;
      end;
   end;
   BaseAsCallback(exec,
      function(n : Integer) : PVariant
      begin
         destPVariant := initial(n);
         Result := itemPtr;
      end, loopCallback);
{$ENDIF}
end;

// EvalAsCallbackString
//
procedure TArrayMapExpr.EvalAsCallbackString(exec : TdwsExecution; const initial, callback : TArrayDataEnumeratorCallbackString);
var
   itemAddr : Integer;
   itemPtr : PVariant;
   funcPointer : IFuncPointer;
   destString : PString;

{$IFDEF FPC}
   function A(n : Integer) : PVariant;
   begin
      Result := itemPtr;
      destString := initial(n);
   end;

   function B(n : Integer) : PVariant;
   begin
      funcPointer.EvalAsString(exec, MapFuncExpr, destString^);
      Result := itemPtr;
      destString := callback(n);
   end;
{$ENDIF}

begin
   MapFuncExpr.EvalAsFuncPointer(exec, funcPointer);

   itemAddr := exec.Stack.BasePointer + FItem.StackAddr;
   itemPtr := @exec.Stack.Data[itemAddr];

{$IFDEF FPC}
   BaseAsCallback(exec, @A, @B);
{$ELSE}
   BaseAsCallback(exec,
      function(n : Integer) : PVariant
      begin
         Result := itemPtr;
         destString := initial(n);
      end,
      function(n : Integer) : PVariant
      begin
         funcPointer.EvalAsString(exec, MapFuncExpr, destString^);
         Result := itemPtr;
         destString := callback(n);
      end
   );
{$ENDIF}
end;

// GetSubExpr
//
function TArrayMapExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   if i=0 then
      Result:=BaseExpr
   else Result:=MapFuncExpr;
end;

// GetSubExprCount
//
function TArrayMapExpr.GetSubExprCount : Integer;
begin
   Result:=2;
end;

// ------------------
// ------------------ TArrayFilterExpr ------------------
// ------------------

// Create
//
constructor TArrayFilterExpr.Create(context : TdwsCompilerContext; const scriptPos: TScriptPos;
                                   aBase : TTypedExpr; aFilterFunc : TFuncPtrExpr);
var
   elemTyp : TTypeSymbol;
begin
   inherited Create(context, scriptPos, aBase);
   FFilterFuncExpr := aFilterFunc;
   Typ := aBase.Typ;

   if aFilterFunc <> nil then begin
      elemTyp := aFilterFunc.FuncSym.Params[0].Typ;
      FItem := TScriptDataSymbol.Create('', elemTyp);
      context.Table.AddSymbol(FItem);
      FFilterFuncExpr.AddArg(TVarExpr.CreateTyped(context, FItem));
      FFilterFuncExpr.InitializeResultAddr(context.Prog as TdwsProgram);
   end;
end;

// Destroy
//
destructor TArrayFilterExpr.Destroy;
begin
   inherited;
   FFilterFuncExpr.Free;
end;

// EvalAsVariant
//
procedure TArrayFilterExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   dyn : IScriptDynArray;
begin
   EvalAsScriptDynArray(exec, dyn);
   VarCopySafe(Result, dyn);
end;

// EvalAsScriptDynArray
//
procedure TArrayFilterExpr.EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray);
var
   newArray : TScriptDynamicArray;
   base : IScriptDynArray;
   dyn : TScriptDynamicValueArray;
   i, k, elementSize, itemAddr : Integer;
   funcPointer : IFuncPointer;
   newPData, oldPData : PData;
begin
   BaseExpr.EvalAsScriptDynArray(exec, base);
   FilterFuncExpr.EvalAsFuncPointer(exec, funcPointer);

   dyn := TScriptDynamicValueArray(base.GetSelf);
   oldPData := dyn.AsPData;

   newArray := TScriptDynamicArray.CreateNew(dyn.ElementTyp);
   result := IScriptDynArray(newArray);
   newArray.ArrayLength := dyn.ArrayLength;
   newPData := newArray.AsPData;
   elementSize := newArray.ElementSize;
   k := 0;

   itemAddr := exec.Stack.BasePointer + FItem.StackAddr;
   if elementSize = 1 then begin
      for i := 0 to dyn.ArrayLength-1 do begin
         exec.Stack.WriteValue(itemAddr, oldPData^[i]);
         if funcPointer.EvalAsBoolean(exec, FilterFuncExpr) then begin
            VarCopySafe(newPData^[k], oldPData^[i]);
            Inc(k);
         end;
      end;
   end else begin
      for i := 0 to dyn.ArrayLength-1 do begin
         dyn.CopyData(i*dyn.ElementSize, exec.Stack.Data, itemAddr, dyn.ElementSize);
         if funcPointer.EvalAsBoolean(exec, FilterFuncExpr) then begin
            dyn.CopyData(i*dyn.ElementSize, newPData^, k*elementSize, elementSize);
            Inc(k);
         end;
      end;
   end;

   if k <> newArray.ArrayLength then
      newArray.ArrayLength := k;
end;

// GetSubExpr
//
function TArrayFilterExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   if i = 0 then
      Result := BaseExpr
   else Result := FilterFuncExpr;
end;

// GetSubExprCount
//
function TArrayFilterExpr.GetSubExprCount : Integer;
begin
   Result := 2;
end;

// ------------------
// ------------------ TArrayReverseExpr ------------------
// ------------------

// EvalAsScriptDynArray
//
procedure TArrayReverseExpr.EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray);
begin
   BaseExpr.EvalAsScriptDynArray(exec, result);
   result.Reverse;
end;

// ------------------
// ------------------ TArrayAddExpr ------------------
// ------------------

// Create
//
constructor TArrayAddExpr.Create(const scriptPos: TScriptPos;
                                 aBase :  TTypedExpr; argExprs : TTypedExprList);
var
   i : Integer;
begin
   inherited Create(scriptPos, aBase);
   if argExprs<>nil then
      for i:=0 to argExprs.Count-1 do
         FArgs.Add(argExprs[i]);
end;

// Destroy
//
destructor TArrayAddExpr.Destroy;
begin
   inherited;
   FArgs.Clean;
end;

// DoEval
//
procedure TArrayAddExpr.DoEval(exec : TdwsExecution; var base : IScriptDynArray);
var
   src : IScriptDynArray;
   dyn, dynSrc : TScriptDynamicArray;
   i, n, k : Integer;
   arg : TTypedExpr;
   argData : TDataExpr;
begin
   BaseExpr.EvalAsScriptDynArray(exec, base);
   dyn:=TScriptDynamicArray(base.GetSelf);

   for i:=0 to FArgs.Count-1 do begin
      arg:=TTypedExpr(FArgs.List[i]);

      if dyn.ElementTyp.IsCompatible(arg.Typ) then begin

         n:=dyn.ArrayLength;
         dyn.ArrayLength:=n+1;
         if arg.Typ.Size>1 then begin
            argData:=(arg as TDataExpr);
            dyn.WriteData(n*dyn.ElementSize, argData.DataPtr[exec], dyn.ElementSize);
         end else arg.EvalAsVariant(exec, dyn.AsPVariant(n)^);

      end else if arg.Typ.ClassType=TDynamicArraySymbol then begin

         arg.EvalAsScriptDynArray(exec, src);
         dynSrc:=(src.GetSelf as TScriptDynamicArray);

         dyn.Concat(dynSrc);

      end else begin

         Assert(arg.Typ is TStaticArraySymbol);

         k:=arg.Typ.Size div dyn.ElementSize;
         if k>0 then begin
            n:=dyn.ArrayLength;
            dyn.ArrayLength:=n+k;
            if arg is TArrayConstantExpr then
               TArrayConstantExpr(arg).EvalToTData(exec, dyn.AsPData^, n*dyn.ElementSize)
            else dyn.WriteData(n*dyn.ElementSize, (arg as TDataExpr).DataPtr[exec], k*dyn.ElementSize);
         end;

      end;
   end;
end;

// EvalNoResult
//
procedure TArrayAddExpr.EvalNoResult(exec : TdwsExecution);
var
   base : IScriptDynArray;
begin
   DoEval(exec, base);
end;

// AddArg
//
procedure TArrayAddExpr.AddArg(expr : TTypedExpr);
begin
   FArgs.Add(expr);
end;

// ExtractArgs
//
procedure TArrayAddExpr.ExtractArgs(destination : TArrayAddExpr);
var
   i : Integer;
begin
   for i:=0 to FArgs.Count-1 do
      destination.FArgs.Add(FArgs.List[i]);
   FArgs.Clear;
end;

// SpecializeProgramExpr
//
function TArrayAddExpr.SpecializeProgramExpr(const context : ISpecializationContext) : TProgramExpr;
var
   i : Integer;
   specialized : TArrayAddExpr;
   arg : TTypedExpr;
   elemTyp : TTypeSymbol;
begin
   specialized := TArrayAddExpr.Create(ScriptPos, BaseExpr.SpecializeTypedExpr(context), nil);
   Result := specialized;
   if BaseExpr = nil then Exit;
   elemTyp := specialized.BaseExpr.Typ.Typ;
   for i := 0 to ArgCount-1 do begin
      arg := ArgExpr[i].SpecializeTypedExpr(context);
      if (arg <> nil) and (not arg.Typ.IsOfType(elemTyp)) then
         specialized.AddArg(
            CompilerUtils.WrapWithImplicitConversion(
               (context.BaseSymbols as TdwsCompilerContext),
               arg, elemTyp,
               arg.ScriptPos,
               CPE_IncompatibleParameterTypes
            )
         )
      else specialized.AddArg(arg);
   end;
end;

// GetSubExpr
//
function TArrayAddExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   if i=0 then
      Result:=FBaseExpr
   else Result:=TExprBase(FArgs.List[i-1]);
end;

// GetSubExprCount
//
function TArrayAddExpr.GetSubExprCount : Integer;
begin
   Result:=1+FArgs.Count;
end;

// GetItemExpr
//
function TArrayAddExpr.GetItemExpr(idx : Integer) : TTypedExpr;
begin
   Result:=TTypedExpr(FArgs.List[idx]);
end;

// ------------------
// ------------------ TArrayDataExpr ------------------
// ------------------

// Create
//
constructor TArrayDataExpr.Create(context : TdwsCompilerContext; const scriptPos: TScriptPos;
                            aBase :  TTypedExpr);
begin
   inherited Create(scriptPos, (aBase.Typ as TDynamicArraySymbol).Typ);
   FBaseExpr:=aBase;
   FResultAddr:=context.GetTempAddr(Typ.Size);
end;

// Destroy
//
destructor TArrayDataExpr.Destroy;
begin
   inherited;
   FBaseExpr.Free;
end;

// GetDataPtr
//
procedure TArrayDataExpr.GetDataPtr(exec : TdwsExecution; var result : IDataContext);
begin
   EvalNoResult(exec);
   exec.DataContext_CreateBase(FResultAddr, Result);
end;

// GetSubExpr
//
function TArrayDataExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   Result:=FBaseExpr;
end;

// GetSubExprCount
//
function TArrayDataExpr.GetSubExprCount : Integer;
begin
   Result:=1;
end;

// GetBaseDynArray
//
function TArrayDataExpr.GetBaseDynArray(exec : TdwsExecution) : TScriptDynamicArray;
var
   base : IScriptDynArray;
begin
   BaseExpr.EvalAsScriptDynArray(exec, base);
   Result:=TScriptDynamicArray(base.GetSelf);
end;

// ------------------
// ------------------ TArrayPeekExpr ------------------
// ------------------

// EvalNoResult
//
procedure TArrayPeekExpr.EvalNoResult(exec : TdwsExecution);
var
   dyn : TScriptDynamicArray;
   idx : Integer;
begin
   dyn := GetBaseDynArray(exec);
   idx := dyn.ArrayLength - 1;
   if idx < 0 then
      RaiseUpperExceeded(exec, 0);

   if dyn.ElementSize = 1 then begin
      dyn.EvalAsVariant(idx, exec.Stack.Data[exec.Stack.BasePointer+FResultAddr]);
   end else begin
      dyn.CopyData(idx*dyn.ElementSize, exec.Stack.Data, exec.Stack.BasePointer+FResultAddr, dyn.ElementSize);
   end;
end;

// SpecializeDataExpr
//
function TArrayPeekExpr.SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr;
begin
   Result := TArrayPeekExpr.Create(
      CompilerContextFromSpecialization(context),
      ScriptPos,
      BaseExpr.SpecializeTypedExpr(context)
   );
end;

// ------------------
// ------------------ TArrayPopExpr ------------------
// ------------------

// EvalNoResult
//
procedure TArrayPopExpr.EvalNoResult(exec : TdwsExecution);
var
   dyn : TScriptDynamicArray;
begin
   inherited EvalNoResult(exec);

   dyn:=GetBaseDynArray(exec);
   dyn.Delete(dyn.ArrayLength-1, 1);
end;

// SpecializeDataExpr
//
function TArrayPopExpr.SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr;
begin
   Result := TArrayPopExpr.Create(
      CompilerContextFromSpecialization(context),
      ScriptPos,
      BaseExpr.SpecializeTypedExpr(context)
   );
end;

// ------------------
// ------------------ TArrayDeleteExpr ------------------
// ------------------

// Create
//
constructor TArrayDeleteExpr.Create(const scriptPos: TScriptPos;
                                    aBase, aIndex, aCount : TTypedExpr);
begin
   inherited Create(scriptPos, aBase);
   FIndexExpr:=aIndex;
   FCountExpr:=aCount;
end;

// Destroy
//
destructor TArrayDeleteExpr.Destroy;
begin
   inherited;
   FIndexExpr.Free;
   FCountExpr.Free;
end;

// EvalNoResult
//
procedure TArrayDeleteExpr.EvalNoResult(exec : TdwsExecution);
var
   base : IScriptDynArray;
   dyn : TScriptDynamicArray;
   index, count : Integer;
begin
   BaseExpr.EvalAsScriptDynArray(exec, base);
   dyn:=TScriptDynamicArray(base.GetSelf);
   index:=IndexExpr.EvalAsInteger(exec);
   BoundsCheck(exec, dyn.ArrayLength, index);
   if CountExpr<>nil then begin
      count:=CountExpr.EvalAsInteger(exec);
      if count<0 then
         RaiseScriptError(exec, EScriptError.CreateFmt(RTE_PositiveCountExpected, [count]));
      BoundsCheck(exec, dyn.ArrayLength, index+count-1);
   end else count:=1;
   dyn.Delete(index, count);
end;

// GetSubExpr
//
function TArrayDeleteExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   case i of
      0 : Result:=FBaseExpr;
      1 : Result:=FIndexExpr;
   else
      Result:=FCountExpr;
   end;
end;

// GetSubExprCount
//
function TArrayDeleteExpr.GetSubExprCount : Integer;
begin
   Result:=3;
end;

// ------------------
// ------------------ TArrayCopyExpr ------------------
// ------------------

// Create
//
constructor TArrayCopyExpr.Create(context : TdwsCompilerContext; const scriptPos: TScriptPos;
                                  aBase, aIndex, aCount : TTypedExpr);
begin
   inherited Create(context, scriptPos, aBase);
   FTyp:=aBase.Typ;
   FIndexExpr:=aIndex;
   FCountExpr:=aCount;
end;

// Destroy
//
destructor TArrayCopyExpr.Destroy;
begin
   inherited;
   FIndexExpr.Free;
   FCountExpr.Free;
end;

// EvalAsVariant
//
procedure TArrayCopyExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   dyn : IScriptDynArray;
begin
   EvalAsScriptDynArray(exec, dyn);
   VarCopySafe(Result, dyn);
end;

// EvalAsScriptDynArray
//
procedure TArrayCopyExpr.EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray);
var
   base : IScriptDynArray;
   dyn, newDyn : TScriptDynamicArray;
   index, count : Integer;
begin
   BaseExpr.EvalAsScriptDynArray(exec, base);
   dyn:=TScriptDynamicArray(base.GetSelf);
   if IndexExpr<>nil then begin
      index:=IndexExpr.EvalAsInteger(exec);
      BoundsCheck(exec, dyn.ArrayLength, index);
   end else index:=0;
   if CountExpr<>nil then begin
      count:=CountExpr.EvalAsInteger(exec);
      if count<0 then
         RaiseScriptError(exec, EScriptError.CreateFmt(RTE_PositiveCountExpected, [count]));
      if index+count >= dyn.ArrayLength then
         count := dyn.ArrayLength-index;
   end else count:=dyn.ArrayLength-index;

   newDyn:=TScriptDynamicArray.CreateNew(dyn.ElementTyp);
   if count>0 then
      newDyn.Copy(dyn, index, count);
   Result:=newDyn;
end;

// GetSubExpr
//
function TArrayCopyExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   case i of
      0 : Result:=FBaseExpr;
      1 : Result:=FIndexExpr;
   else
      Result:=FCountExpr;
   end;
end;

// GetSubExprCount
//
function TArrayCopyExpr.GetSubExprCount : Integer;
begin
   Result:=3;
end;

// ------------------
// ------------------ TArrayIndexOfExpr ------------------
// ------------------

// Create
//
constructor TArrayIndexOfExpr.Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                                            aBase : TTypedExpr; aItem : TTypedExpr; aFromIndex : TTypedExpr);
begin
   inherited Create(context, scriptPos, aBase);
   FItemExpr:=aItem;
   FFromIndexExpr:=aFromIndex;
   Typ:=context.TypInteger;
end;

// Destroy
//
destructor TArrayIndexOfExpr.Destroy;
begin
   inherited;
   FItemExpr.Free;
   FFromIndexExpr.Free;
end;

// EvalAsVariant
//
procedure TArrayIndexOfExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
begin
   VarCopySafe(Result, EvalAsInteger(exec));
end;

// GetSubExpr
//
function TArrayIndexOfExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   case i of
      0 : Result:=FBaseExpr;
      1 : Result:=FItemExpr;
   else
      Result:=FFromIndexExpr;
   end;
end;

// GetSubExprCount
//
function TArrayIndexOfExpr.GetSubExprCount : Integer;
begin
   Result:=3
end;

// ------------------
// ------------------ TDynamicArrayIndexOfExpr ------------------
// ------------------

// Create
//
constructor TDynamicArrayIndexOfExpr.Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                                            aBase : TTypedExpr; aItem : TTypedExpr; aFromIndex : TTypedExpr);
var
   arrayItemTyp : TTypeSymbol;
begin
   inherited Create(context, scriptPos, aBase, aItem, aFromIndex);
   // resolve internal method depending on array and item type
   if (FItemExpr<>nil) and (FItemExpr.Typ.AsFuncSymbol<>nil) then
      FMethod:=DoEvalFuncPtr
   else if (FBaseExpr<>nil) and (FBaseExpr.Typ<>nil) then begin
      arrayItemTyp:=FBaseExpr.Typ.Typ;
      if arrayItemTyp<>nil then begin
         if arrayItemTyp.Size>1 then
            FMethod:=DoEvalData
         else if arrayItemTyp.IsOfType(context.TypString) then
            FMethod:=DoEvalString
         else if arrayItemTyp.IsOfType(context.TypInteger) then
            FMethod:=DoEvalInteger
         else FMethod:=DoEvalValue;
      end;
   end;
end;

// EvalAsInteger
//
function TDynamicArrayIndexOfExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
var
   base : IScriptDynArray;
   dyn : TScriptDynamicArray;
begin
   BaseExpr.EvalAsScriptDynArray(exec, base);
   dyn:=TScriptDynamicArray(base.GetSelf);
   Result:=FMethod(exec, dyn);
end;

// DoEvalValue
//
function TDynamicArrayIndexOfExpr.DoEvalValue(exec : TdwsExecution; dyn : TScriptDynamicArray) : Integer;
var
   fromIndex : Integer;
   v : Variant;
begin
   if FFromIndexExpr<>nil then
      fromIndex:=FFromIndexExpr.EvalAsInteger(exec)
   else fromIndex:=0;
   FItemExpr.EvalAsVariant(exec, v);
   Result:=dyn.IndexOfValue(v, fromIndex, dyn.ArrayLength-1);
end;

// DoEvalString
//
function TDynamicArrayIndexOfExpr.DoEvalString(exec : TdwsExecution; dyn : TScriptDynamicArray) : Integer;
var
   fromIndex : Integer;
   v : String;
begin
   if FFromIndexExpr<>nil then
      fromIndex:=FFromIndexExpr.EvalAsInteger(exec)
   else fromIndex:=0;
   FItemExpr.EvalAsString(exec, v);
   Result:=dyn.IndexOfString(v, fromIndex);
end;

// DoEvalInteger
//
function TDynamicArrayIndexOfExpr.DoEvalInteger(exec : TdwsExecution; dyn : TScriptDynamicArray) : Integer;
var
   fromIndex : Integer;
begin
   if FFromIndexExpr<>nil then
      fromIndex:=FFromIndexExpr.EvalAsInteger(exec)
   else fromIndex:=0;
   Result:=dyn.IndexOfInteger(FItemExpr.EvalAsInteger(exec), fromIndex);
end;

// DoEvalFuncPtr
//
function TDynamicArrayIndexOfExpr.DoEvalFuncPtr(exec : TdwsExecution; dyn : TScriptDynamicArray) : Integer;
var
   fromIndex : Integer;
   v : Variant;
begin
   if FFromIndexExpr<>nil then
      fromIndex:=FFromIndexExpr.EvalAsInteger(exec)
   else fromIndex:=0;
   FItemExpr.EvalAsVariant(exec, v);
   Result:=dyn.IndexOfFuncPtr(v, fromIndex)
end;

// DoEvalData
//
function TDynamicArrayIndexOfExpr.DoEvalData(exec : TdwsExecution; dyn : TScriptDynamicArray) : Integer;
var
   fromIndex : Integer;
begin
   if FFromIndexExpr<>nil then
      fromIndex:=FFromIndexExpr.EvalAsInteger(exec)
   else fromIndex:=0;
   Result:=dyn.IndexOfData(TDataExpr(FItemExpr).DataPtr[exec], fromIndex, dyn.ArrayLength-1, FItemExpr.Typ.Size)
end;

// ------------------
// ------------------ TStaticArrayIndexOfExpr ------------------
// ------------------

// EvalAsInteger
//
function TStaticArrayIndexOfExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
var
   fromIndex : Integer;
   arrayDC : IDataContext;
   dc : TDataContext;
   value : Variant;
   arrayTyp : TStaticArraySymbol;
begin
   arrayTyp := BaseExpr.Typ as TStaticArraySymbol;
   if FFromIndexExpr<>nil then begin
      fromIndex := FFromIndexExpr.EvalAsInteger(exec);
      if fromIndex < arrayTyp.LowBound then
         fromIndex := arrayTyp.LowBound;
   end else fromIndex := arrayTyp.LowBound;

   arrayDC := (BaseExpr as TDataExpr).DataPtr[exec];
   dc := (arrayDC.GetSelf as TDataContext);

   if FItemExpr.Typ.Size = 1 then begin
      FItemExpr.EvalAsVariant(exec, value);
      Result := dc.IndexOfValue(value, fromIndex - arrayTyp.LowBound, arrayTyp.ElementCount - 1);
   end else begin
      Result := TDataContext(arrayDC.GetSelf).IndexOfData(
         TDataExpr(FItemExpr).DataPtr[exec],
         fromIndex - arrayTyp.LowBound, arrayTyp.ElementCount - 1,
         FItemExpr.Typ.Size
      );
   end;
   if not ForceZeroBased then
      if (Result >= 0) or (arrayTyp.LowBound < 0) then
         Result := Result + arrayTyp.LowBound;
end;

// ------------------
// ------------------ TArrayRemoveExpr ------------------
// ------------------

// EvalAsInteger
//
function TArrayRemoveExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
var
   index : Integer;
   base : IScriptDynArray;
   dyn : TScriptDynamicArray;
begin
   BaseExpr.EvalAsScriptDynArray(exec, base);
   dyn:=TScriptDynamicArray(base.GetSelf);
   index:=FMethod(exec, dyn);
   if index>=0 then
      dyn.Delete(index, 1);
   Result:=index;
end;

// ------------------
// ------------------ TArrayInsertExpr ------------------
// ------------------

// Create
//
constructor TArrayInsertExpr.Create(const scriptPos: TScriptPos;
                                    aBase, aIndex : TTypedExpr; aItem : TTypedExpr);
begin
   inherited Create(scriptPos, aBase);
   FIndexExpr:=aIndex;
   FItemExpr:=aItem;
end;

// Destroy
//
destructor TArrayInsertExpr.Destroy;
begin
   inherited;
   FIndexExpr.Free;
   FItemExpr.Free;
end;

// EvalNoResult
//
procedure TArrayInsertExpr.EvalNoResult(exec : TdwsExecution);
var
   base : IScriptDynArray;
   dyn : TScriptDynamicArray;
   n, index : Integer;
begin
   BaseExpr.EvalAsScriptDynArray(exec, base);
   dyn:=TScriptDynamicArray(base.GetSelf);

   n:=dyn.ArrayLength;

   index:=IndexExpr.EvalAsInteger(exec);
   if index=n then
      dyn.ArrayLength:=n+1
   else begin
      BoundsCheck(exec, n, index);
      dyn.Insert(index);
   end;

   if ItemExpr.Typ.Size>1 then
      dyn.WriteData(index*dyn.ElementSize, (ItemExpr as TDataExpr).DataPtr[exec], dyn.ElementSize)
   else ItemExpr.EvalAsVariant(exec, dyn.AsPVariant(index)^);
end;

// GetSubExpr
//
function TArrayInsertExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   case i of
      0 : Result:=FBaseExpr;
      1 : Result:=FIndexExpr;
   else
      Result:=FItemExpr;
   end;
end;

// GetSubExprCount
//
function TArrayInsertExpr.GetSubExprCount : Integer;
begin
   Result:=3;
end;

// ------------------
// ------------------ TArrayMoveExpr ------------------
// ------------------

// Create
//
constructor TArrayMoveExpr.Create(const scriptPos: TScriptPos;
                            aBase, anOriginIndex, aDestinationIndex : TTypedExpr);
begin
   inherited Create(scriptPos, aBase);
   FOriginIndexExpr := anOriginIndex;
   FDestinationIndexExpr := aDestinationIndex;
end;

// Destroy
//
destructor TArrayMoveExpr.Destroy;
begin
   inherited;
   FOriginIndexExpr.Free;
   FDestinationIndexExpr.Free;
end;

// EvalNoResult
//
procedure TArrayMoveExpr.EvalNoResult(exec : TdwsExecution);
var
   base : IScriptDynArray;
   dyn : TScriptDynamicArray;
   n, indexOrigin, indexDest : Integer;
begin
   BaseExpr.EvalAsScriptDynArray(exec, base);
   dyn:=TScriptDynamicArray(base.GetSelf);

   n:=dyn.ArrayLength;

   indexOrigin := OriginIndexExpr.EvalAsInteger(exec);
   BoundsCheck(exec, n, indexOrigin);
   indexDest := DestinationIndexExpr.EvalAsInteger(exec);
   BoundsCheck(exec, n, indexDest);

   if indexOrigin <> indexDest then
      dyn.MoveItem(indexOrigin, indexDest);
end;

// GetSubExpr
//
function TArrayMoveExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   case i of
      0 : Result := FBaseExpr;
      1 : Result := FOriginIndexExpr;
   else
      Result := FDestinationIndexExpr;
   end;
end;

// GetSubExprCount
//
function TArrayMoveExpr.GetSubExprCount : Integer;
begin
   Result := 3;
end;

// ------------------
// ------------------ TImplementsIntfOpExpr ------------------
// ------------------

// EvalAsBoolean
//
function TImplementsIntfOpExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   scriptObj : IScriptObj;
   typIntf : TInterfaceSymbol;
begin
   Left.EvalAsScriptObj(exec, scriptObj);

   if Assigned(scriptObj) then begin
      typIntf:=TInterfaceSymbol(Right.EvalAsInteger(exec));
      Result:=scriptObj.ClassSym.ImplementsInterface(typIntf);
   end else Result:=False;
end;

// ------------------
// ------------------ TClassImplementsIntfOpExpr ------------------
// ------------------

// EvalAsBoolean
//
function TClassImplementsIntfOpExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   classSym : TClassSymbol;
   typIntf : TInterfaceSymbol;
begin
   classSym:=TClassSymbol(Left.EvalAsInteger(exec));

   if Assigned(classSym) then begin
      typIntf:=TInterfaceSymbol(Right.EvalAsInteger(exec));
      Result:=classSym.ImplementsInterface(typIntf);
   end else Result:=False;
end;

// ------------------
// ------------------ TResourceStringExpr ------------------
// ------------------

// Create
//
constructor TResourceStringExpr.Create(context : TdwsCompilerContext; const aScriptPos : TScriptPos; aRes : TResourceStringSymbol);
begin
   inherited Create;
   FScriptPos:=aScriptPos;
   FResSymbol:=aRes;
   Typ:=context.TypString;
end;

// ScriptPos
//
function TResourceStringExpr.ScriptPos : TScriptPos;
begin
   Result:=FScriptPos;
end;

// EvalAsVariant
//
procedure TResourceStringExpr.EvalAsVariant(exec : TdwsExecution; var result : Variant);
var
   buf : String;
begin
   exec.LocalizeSymbol(FResSymbol, buf);
   VarCopySafe(Result, buf);
end;

// EvalAsString
//
procedure TResourceStringExpr.EvalAsString(exec : TdwsExecution; var result : String);
begin
   exec.LocalizeSymbol(FResSymbol, Result);
end;

// ------------------
// ------------------ TSwapExpr ------------------
// ------------------

// Create
//
constructor TSwapExpr.Create(context : TdwsCompilerContext; const scriptPos : TScriptPos;
                             expr0, expr1 : TDataExpr);
begin
   inherited Create(scriptPos);
   FArg0:=expr0;
   FArg1:=expr1;
end;

// Destroy
//
destructor TSwapExpr.Destroy;
begin
   FArg0.Free;
   FArg1.Free;
   inherited;
end;

// EvalNoResult
//
procedure TSwapExpr.EvalNoResult(exec : TdwsExecution);

   procedure Swap1;
   var
      tmp, tmp2 : Variant;
   begin
      Arg0.EvalAsVariant(exec, tmp);
      Arg1.EvalAsVariant(exec, tmp2);
      Arg0.AssignValue(exec, tmp2);
      Arg1.AssignValue(exec, tmp);
   end;

   procedure SwapN(size : Integer);
   var
      buf : TData;
      dataPtr0, dataPtr1 : IDataContext;
   begin
      SetLength(buf, size);
      dataPtr0:=Arg0.DataPtr[exec];
      dataPtr1:=Arg1.DataPtr[exec];
      dataPtr0.CopyData(buf, 0, size);
      dataPtr0.WriteData(dataPtr1, size);
      dataPtr1.WriteData(buf, 0, size);
   end;

var
   size : Integer;
begin
   size:=Arg0.Typ.Size;
   if size=1 then
      Swap1
   else SwapN(size);
end;

// GetSubExpr
//
function TSwapExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   if i=0 then
      Result:=Arg0
   else Result:=Arg1;
end;

// GetSubExprCount
//
function TSwapExpr.GetSubExprCount : Integer;
begin
   Result:=2;
end;

// ------------------
// ------------------ TForInStrExpr ------------------
// ------------------

// Create
//
constructor TForInStrExpr.Create(context : TdwsCompilerContext; const aPos: TScriptPos;
         aVarExpr : TVarExpr; aInExpr : TTypedExpr);
begin
   inherited Create(aPos);
   FVarExpr:=aVarExpr;
   FInExpr:=aInExpr;
end;

// Destroy
//
destructor TForInStrExpr.Destroy;
begin
   FDoExpr.Free;
   FInExpr.Free;
   FVarExpr.Free;
   inherited;
end;

// EnumerateSteppableExprs
//
procedure TForInStrExpr.EnumerateSteppableExprs(const callback : TExprBaseProc);
begin
   callback(DoExpr);
end;

// GetSubExpr
//
function TForInStrExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   case i of
      0 : Result:=FVarExpr;
      1 : Result:=FInExpr;
   else
      Result:=FDoExpr;
   end;
end;

// GetSubExprCount
//
function TForInStrExpr.GetSubExprCount : Integer;
begin
   Result:=3;
end;

// ------------------
// ------------------ TForCharCodeInStrExpr ------------------
// ------------------

// Create
//
constructor TForCharCodeInStrExpr.Create(context : TdwsCompilerContext; const aPos: TScriptPos;
         aVarExpr : TIntVarExpr; aInExpr : TTypedExpr);
begin
   inherited Create(context, aPos, aVarExpr, aInExpr);
end;

// EvalNoResult
//
procedure TForCharCodeInStrExpr.EvalNoResult(exec : TdwsExecution);
var
   code, i : Integer;
   v : PInt64;
   p : PWideChar;
   s : String;
begin
   FInExpr.EvalAsString(exec, s);

   v:=TIntVarExpr(FVarExpr).EvalAsPInteger(exec);

   p:=PWideChar(s);
   for i:=1 to Length(s) do begin
      code:=Ord(p^);
      Inc(p);
      case code of
         $D800..$DBFF : // high surrogate
            v^:=(code-$D800)*$400+(Ord(p^)-$DC00)+$10000;
         $DC00..$DFFF : //low surrogate
            continue;
      else
         v^:=code;
      end;

      exec.DoStep(FDoExpr);
      FDoExpr.EvalNoResult(exec);
      if exec.Status<>esrNone then begin
         case exec.Status of
            esrBreak : begin
               exec.Status:=esrNone;
               break;
            end;
            esrContinue :
               exec.Status:=esrNone;
            esrExit : Exit;
         end;
      end;
   end;
end;

// ------------------
// ------------------ TForCharCodeInStrExpr ------------------
// ------------------

// Create
//
constructor TForCharInStrExpr.Create(context : TdwsCompilerContext; const aPos: TScriptPos;
         aVarExpr : TStrVarExpr; aInExpr : TTypedExpr);
begin
   inherited Create(context, aPos, aVarExpr, aInExpr);
end;

// EvalNoResult
//
procedure TForCharInStrExpr.EvalNoResult(exec : TdwsExecution);
var
   code, i : Integer;
   p : PWideChar;
   s : UnicodeString;
   strVarExpr : TStrVarExpr;
begin
   FInExpr.EvalAsUnicodeString(exec, s);

   strVarExpr:=TStrVarExpr(FVarExpr);

   p:=PWideChar(s);
   for i:=1 to Length(s) do begin
      code:=Ord(p^);
      Inc(p);
      case code of
         $D800..$DBFF : // high surrogate
            strVarExpr.AssignValueAsUnicodeString(exec, WideChar(code)+p^);
         $DC00..$DFFF : //low surrogate
            continue;
      else
         strVarExpr.AssignValueAsWideChar(exec, WideChar(code));
      end;

      exec.DoStep(FDoExpr);
      FDoExpr.EvalNoResult(exec);
      if exec.Status<>esrNone then begin
         case exec.Status of
            esrBreak : begin
               exec.Status:=esrNone;
               break;
            end;
            esrContinue :
               exec.Status:=esrNone;
            esrExit : Exit;
         end;
      end;
   end;
end;

// ------------------
// ------------------ TIfThenElseValueExpr ------------------
// ------------------

// Create
//
constructor TIfThenElseValueExpr.Create(context : TdwsCompilerContext; const aPos : TScriptPos;
                                        aTyp : TTypeSymbol;
                                        condExpr, trueExpr, falseExpr : TTypedExpr);
begin
   inherited Create(aTyp);
   FScriptPos:=aPos;
   FCondExpr:=condExpr;
   FTrueExpr:=trueExpr;
   FFalseExpr:=falseExpr;
end;

// Destroy
//
destructor TIfThenElseValueExpr.Destroy;
begin
   FCondExpr.Free;
   FFalseExpr.Free;
   FTrueExpr.Free;
   inherited;
end;

// EvalAsVariant
//
procedure TIfThenElseValueExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
begin
   if FCondExpr.EvalAsBoolean(exec) then
      FTrueExpr.EvalAsVariant(exec, Result)
   else FFalseExpr.EvalAsVariant(exec, Result);
end;

// EvalAsInteger
//
function TIfThenElseValueExpr.EvalAsInteger(exec : TdwsExecution) : Int64;
begin
   if FCondExpr.EvalAsBoolean(exec) then
      Result := FTrueExpr.EvalAsInteger(exec)
   else Result := FFalseExpr.EvalAsInteger(exec);
end;

// EvalAsFloat
//
function TIfThenElseValueExpr.EvalAsFloat(exec : TdwsExecution) : Double;
begin
   if FCondExpr.EvalAsBoolean(exec) then
      Result := FTrueExpr.EvalAsFloat(exec)
   else Result := FFalseExpr.EvalAsFloat(exec);
end;

// EvalAsString
//
procedure TIfThenElseValueExpr.EvalAsString(exec : TdwsExecution; var result : String);
begin
   if FCondExpr.EvalAsBoolean(exec) then
      FTrueExpr.EvalAsString(exec, result)
   else FFalseExpr.EvalAsString(exec, result);
end;

// GetDataPtr
//
procedure TIfThenElseValueExpr.GetDataPtr(exec : TdwsExecution; var result : IDataContext);
var
   e : TTypedExpr;
begin
   if FCondExpr.EvalAsBoolean(exec) then
      e := FTrueExpr
   else e := FFalseExpr;
   (e as TDataExpr).GetDataPtr(exec, result);
end;

// GetIsConstant
//
function TIfThenElseValueExpr.GetIsConstant : Boolean;
begin
   Result:=FCondExpr.IsConstant and FTrueExpr.IsConstant and FFalseExpr.IsConstant;
end;

// Optimize
//
function TIfThenElseValueExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
var
   bufExpr : TTypedExpr;
   notExpr : TNotBoolExpr;
begin
   if FCondExpr.IsConstant then begin
      if FCondExpr.EvalAsBoolean(context.Execution) then begin
         Result:=FTrueExpr;
         FTrueExpr:=nil;
      end else begin
         Result:=FFalseExpr;
         FFalseExpr:=nil;
      end;
      Orphan(context);
   end else begin
      Result:=Self;
      if CondExpr is TNotBoolExpr then begin
         notExpr:=TNotBoolExpr(CondExpr);
         CondExpr:=notExpr.Expr;
         notExpr.Expr:=nil;
         notExpr.Orphan(context);
         bufExpr:=TrueExpr;
         TrueExpr:=FalseExpr;
         FalseExpr:=bufExpr;
      end;
   end;
end;

// SpecializeDataExpr
//
function TIfThenElseValueExpr.SpecializeDataExpr(const context : ISpecializationContext) : TDataExpr;
begin
   Result := TIfThenElseValueExpr.Create(
      CompilerContextFromSpecialization(context), ScriptPos,
      context.SpecializeType(Typ),
      CondExpr.SpecializeBooleanExpr(context),
      TrueExpr.SpecializeTypedExpr(context),
      FalseExpr.SpecializeTypedExpr(context)
   );
end;

// GetSubExpr
//
function TIfThenElseValueExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   case i of
      0 : Result:=FCondExpr;
      1 : Result:=FTrueExpr;
   else
      Result:=FFalseExpr;
   end;
end;

// GetSubExprCount
//
function TIfThenElseValueExpr.GetSubExprCount : Integer;
begin
   Result:=3;
end;

// ScriptPos
//
function TIfThenElseValueExpr.ScriptPos : TScriptPos;
begin
   Result := FScriptPos;
end;

// ------------------
// ------------------ TArrayConcatExpr ------------------
// ------------------

// Create
//
constructor TArrayConcatExpr.Create(const scriptPos : TScriptPos; aTyp: TDynamicArraySymbol);
var
   newArray : TNewArrayExpr;
begin
   inherited Create(scriptPos, aTyp);
   newArray:=TNewArrayExpr.Create(scriptPos, aTyp);
   FAddExpr:=TArrayAddExpr.Create(scriptPos, newArray, nil);
end;

// Destroy
//
destructor TArrayConcatExpr.Destroy;
begin
   inherited;
   FAddExpr.Free;
end;

// EvalAsScriptDynArray
//
procedure TArrayConcatExpr.EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray);
begin
   FAddExpr.DoEval(exec, result);
end;

// AddArg
//
procedure TArrayConcatExpr.AddArg(arg : TTypedExpr);
var
   concat : TArrayConcatExpr;
begin
   if arg is TArrayConcatExpr then begin

      // coalesce
      concat:=TArrayConcatExpr(arg);
      concat.FAddExpr.ExtractArgs(FAddExpr);
      concat.Free;

   end else FAddExpr.AddArg(arg);
end;

// ArgCount
//
function TArrayConcatExpr.ArgCount : Integer;
begin
   Result:=FAddExpr.SubExprCount-1
end;

// GetSubExpr
//
function TArrayConcatExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   Result:=FAddExpr.SubExpr[i+1];
end;

// GetSubExprCount
//
function TArrayConcatExpr.GetSubExprCount : Integer;
begin
   Result:=FAddExpr.SubExprCount-1;
end;

// GetArgs
//
function TArrayConcatExpr.GetArgs(index : Integer) : TTypedExpr;
begin
   Result:=FAddExpr.ArgExpr[index];
end;

// ------------------
// ------------------ TAssociativeArrayClearExpr ------------------
// ------------------

// EvalNoResult
//
procedure TAssociativeArrayClearExpr.EvalNoResult(exec : TdwsExecution);
var
   aa : IScriptAssociativeArray;
begin
   FBaseExpr.EvalAsScriptAssociativeArray(exec, aa);
   aa.Clear;
end;

// ------------------
// ------------------ TAssociativeArrayDeleteExpr ------------------
// ------------------

// Create
//
constructor TAssociativeArrayDeleteExpr.Create(context : TdwsCompilerContext; aBase, aKey : TTypedExpr);
begin
   inherited Create;
   FBaseExpr := aBase;
   FKeyExpr := aKey;
   Typ := context.TypBoolean;
end;

// Destroy
//
destructor TAssociativeArrayDeleteExpr.Destroy;
begin
   inherited;
   FBaseExpr.Free;
   FKeyExpr.Free;
end;

// EvalAsBoolean
//
function TAssociativeArrayDeleteExpr.EvalAsBoolean(exec : TdwsExecution) : Boolean;
var
   base : IScriptAssociativeArray;
begin
   FBaseExpr.EvalAsScriptAssociativeArray(exec, base);
   Result := (base.GetSelf as TScriptAssociativeArray).Delete(exec, KeyExpr);
end;

// EvalAsVariant
//
procedure TAssociativeArrayDeleteExpr.EvalAsVariant(exec : TdwsExecution; var result : Variant);
begin
   result := EvalAsBoolean(exec);
end;

// EvalNoResult
//
procedure TAssociativeArrayDeleteExpr.EvalNoResult(exec : TdwsExecution);
begin
   EvalAsBoolean(exec);
end;

// GetSubExpr
//
function TAssociativeArrayDeleteExpr.GetSubExpr(i : Integer) : TExprBase;
begin
   if i = 0 then
      Result := BaseExpr
   else Result := KeyExpr;
end;

// GetSubExprCount
//
function TAssociativeArrayDeleteExpr.GetSubExprCount : Integer;
begin
   Result := 2;
end;

// ------------------
// ------------------ TAssociativeArrayKeysExpr ------------------
// ------------------

// Create
//
constructor TAssociativeArrayKeysExpr.Create(context : TdwsBaseSymbolsContext; const aScriptPos : TScriptPos; expr : TTypedExpr);
var
   a : TAssociativeArraySymbol;
begin
   inherited;
   a := (expr.Typ.UnAliasedType as TAssociativeArraySymbol);
   Typ := a.KeysArrayType(context);
end;

// EvalAsVariant
//
procedure TAssociativeArrayKeysExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   dyn : IScriptDynArray;
begin
   EvalAsScriptDynArray(exec, dyn);
   Result := dyn;
end;

// EvalAsScriptDynArray
//
procedure TAssociativeArrayKeysExpr.EvalAsScriptDynArray(exec : TdwsExecution; var result : IScriptDynArray);
var
   a : IScriptAssociativeArray;
   dyn : TScriptDynamicArray;
begin
   Expr.EvalAsScriptAssociativeArray(exec, a);
   dyn := TScriptDynamicArray.CreateNew(Typ.Typ);
   Result := dyn;
   if a <> nil then
      dyn.ReplaceData((a.GetSelf as TScriptAssociativeArray).CopyKeys);
end;

// ------------------
// ------------------ TExternalVarExpr ------------------
// ------------------

// IsExternal
//
function TExternalVarExpr.IsExternal : Boolean;
begin
   Result:=True;
end;

// EvalAsVariant
//
procedure TExternalVarExpr.EvalAsVariant(exec : TdwsExecution; var Result : Variant);
var
   handled : Boolean;
begin
   handled:=False;
   TExternalSymbolHandler.HandleEval(exec, dataSym, handled, Result);
   if not handled then
      raise EdwsExternalFuncHandler.Create('Unsupported external variable access');
end;

// ------------------
// ------------------ TAssignExternalExpr ------------------
// ------------------

// EvalNoResult
//
procedure TAssignExternalExpr.EvalNoResult(exec : TdwsExecution);
var
   handled : Boolean;
   dataSym : TDataSymbol;
begin
   dataSym:=Left.DataSymbol;
   if dataSym<>nil then begin
      handled:=False;
      TExternalSymbolHandler.HandleAssign(exec, dataSym, Right, handled);
      if handled then exit;
   end;
   raise EdwsExternalFuncHandler.Create('Unsupported external variable assignment');
end;

// Optimize
//
function TAssignExternalExpr.Optimize(context : TdwsCompilerContext) : TProgramExpr;
begin
   Result:=Self;
end;

end.
