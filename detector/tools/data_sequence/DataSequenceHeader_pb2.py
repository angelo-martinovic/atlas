# Generated by the protocol buffer compiler.  DO NOT EDIT!

from google.protobuf import descriptor
from google.protobuf import message
from google.protobuf import reflection
from google.protobuf import descriptor_pb2
# @@protoc_insertion_point(imports)



DESCRIPTOR = descriptor.FileDescriptor(
  name='DataSequenceHeader.proto',
  package='biclop_protobuf',
  serialized_pb='\n\x18\x44\x61taSequenceHeader.proto\x12\x0f\x62iclop_protobuf\"4\n\x15\x44\x61taSequenceAttribute\x12\x0c\n\x04name\x18\x01 \x02(\t\x12\r\n\x05value\x18\x02 \x02(\t\"P\n\x12\x44\x61taSequenceHeader\x12:\n\nattributes\x18\x03 \x03(\x0b\x32&.biclop_protobuf.DataSequenceAttribute')




_DATASEQUENCEATTRIBUTE = descriptor.Descriptor(
  name='DataSequenceAttribute',
  full_name='biclop_protobuf.DataSequenceAttribute',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    descriptor.FieldDescriptor(
      name='name', full_name='biclop_protobuf.DataSequenceAttribute.name', index=0,
      number=1, type=9, cpp_type=9, label=2,
      has_default_value=False, default_value=unicode("", "utf-8"),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
    descriptor.FieldDescriptor(
      name='value', full_name='biclop_protobuf.DataSequenceAttribute.value', index=1,
      number=2, type=9, cpp_type=9, label=2,
      has_default_value=False, default_value=unicode("", "utf-8"),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  extension_ranges=[],
  serialized_start=45,
  serialized_end=97,
)


_DATASEQUENCEHEADER = descriptor.Descriptor(
  name='DataSequenceHeader',
  full_name='biclop_protobuf.DataSequenceHeader',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    descriptor.FieldDescriptor(
      name='attributes', full_name='biclop_protobuf.DataSequenceHeader.attributes', index=0,
      number=3, type=11, cpp_type=10, label=3,
      has_default_value=False, default_value=[],
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      options=None),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  options=None,
  is_extendable=False,
  extension_ranges=[],
  serialized_start=99,
  serialized_end=179,
)

_DATASEQUENCEHEADER.fields_by_name['attributes'].message_type = _DATASEQUENCEATTRIBUTE
DESCRIPTOR.message_types_by_name['DataSequenceAttribute'] = _DATASEQUENCEATTRIBUTE
DESCRIPTOR.message_types_by_name['DataSequenceHeader'] = _DATASEQUENCEHEADER

class DataSequenceAttribute(message.Message):
  __metaclass__ = reflection.GeneratedProtocolMessageType
  DESCRIPTOR = _DATASEQUENCEATTRIBUTE
  
  # @@protoc_insertion_point(class_scope:biclop_protobuf.DataSequenceAttribute)

class DataSequenceHeader(message.Message):
  __metaclass__ = reflection.GeneratedProtocolMessageType
  DESCRIPTOR = _DATASEQUENCEHEADER
  
  # @@protoc_insertion_point(class_scope:biclop_protobuf.DataSequenceHeader)

# @@protoc_insertion_point(module_scope)
