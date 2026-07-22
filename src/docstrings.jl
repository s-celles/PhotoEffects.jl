using DocStringExtensions

DocStringExtensions.@template DEFAULT = """
                                        $(TYPEDSIGNATURES)

                                        $(DOCSTRING)
                                        """

DocStringExtensions.@template TYPES = """
                                      $(TYPEDEF)

                                      $(DOCSTRING)

                                      # Fields
                                      $(TYPEDFIELDS)
                                      """
